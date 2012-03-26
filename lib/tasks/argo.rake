namespace :argo do

  desc "Update the .htaccess file from indexed APOs"
  task :htaccess => :environment do
    directives = [
      'AuthType WebAuth',
      'Require privgroup dlss:argo-access',
      'WebAuthLdapAttribute suAffiliation',
      'WebAuthLdapAttribute displayName',
      'WebAuthLdapAttribute mail',
    ]

    resp = Dor::SearchService.query('objectType_facet:adminPolicy', :rows => 0, 
      :facets => { :fields => ['apo_register_permissions_facet'] }, :'facet.prefix' => 'workgroup:', :'facet.mincount' => 1, :'facet.limit' => -1 )
    facet = resp.facets.find { |f| f.name == 'apo_register_permissions_facet' }
    unless facet.nil?
      facets = facet.items.collect &:value
      priv_groups = facets.select { |v| v =~ /^workgroup:/ }
      directives += priv_groups.collect { |v| 
        ["Require privgroup #{v.split(/:/,2).last}", "WebAuthLdapPrivgroup #{v.split(/:/,2).last}"]
      }.flatten
    end
    File.open(File.join(Rails.root, 'public/.htaccess'),'w') do |htaccess|
      htaccess.puts directives.sort.join("\n")
    end
    File.unlink('public/auth/.htaccess') if File.exists?('public/auth/.htaccess')
  end
  
  desc "Reindex all DOR objects"
  task :reindex_all, [:query] => [:environment] do |t, args|
    index_log = Logger.new(File.join(Rails.root,'log','reindex.log'))
    index_log.formatter = Logger::Formatter.new
    index_log.level = ENV['LOG_LEVEL'] ? Logger::SEV_LABEL.index(ENV['LOG_LEVEL']) : Logger::INFO
    $stdout.sync = true
    start_time = Time.now
    $stdout.puts "Discovering PIDs..."
    index_log.info "Discovering PIDs..."
    dor_pids = []
    solr_pids = []
    if args[:query] != ':ALL:'
      q = (args[:query].nil? or args[:query]) == ':MISSING:' ? '*:*' : args[:query]
      puts q
      start = 0
      resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
      while resp.docs.length > 0
        solr_pids += resp.docs.collect { |doc| doc['id'] }
        start += 1000
        $stdout.print "."
        resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
      end
      $stdout.puts
      msg = "Found #{solr_pids.length} PIDs in solr."
      $stdout.puts msg
      index_log.info msg
    end
    if args[:query] =~ /:(ALL|MISSING):/
      dor_pids = Dor::SearchService.risearch("select $object from <#ri> where $object <info:fedora/fedora-system:def/model#label> $label", :limit => '5000000', :timeout => -1)
      msg = "Found #{dor_pids.length} PIDs in DOR."
      $stdout.puts msg
      index_log.info msg
    end
    if dor_pids.present?
      pids = dor_pids - solr_pids
    else
      pids = solr_pids
    end
    pids.delete_if { |pid| pid !~ /druid:/ }
    time = Time.now - start_time
    msg = "#{pids.length} PIDs discovered in #{[(time/3600).floor, (time/60 % 60).floor, (time % 60).floor].map{|t| t.to_s.rjust(2,'0')}.join(':')}"
    $stdout.puts msg
    index_log.info msg

    solr = ActiveFedora.solr.conn
    pbar = ProgressBar.new("Reindexing...", pids.length)
    errors = 0
    pids.each do |pid|
      begin
        index_log.debug "Indexing #{pid}"
        obj = Dor.load_instance pid
        obj = obj.adapt_to(Dor::Item) if obj.class == ActiveFedora::Base
        if obj.is_a?(Dor::Processable) and obj.workflows.new?
          c = obj.class
          obj.workflows.save
          obj = Dor.load_instance(pid).adapt_to c
        end
        solr_doc = obj.to_solr
        solr.add solr_doc, :add_attributes => {:commitWithin => 10}
        errors = 0
      rescue Interrupt
        raise
      rescue Exception => e
        errors += 1
        index_log.warn("Error (#{errors}) indexing #{pid}")
        index_log.error("#{e.class}: #{e.message}")
#        if errors == 3
#          index_log.fatal("Too many errors. Exiting.")
#          raise e 
#        end
      end
      pbar.inc(1)
    end
    solr.commit
  end
  
end