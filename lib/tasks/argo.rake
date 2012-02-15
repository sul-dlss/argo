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

    resp = Dor::SearchService.gsearch(:q=>'object_type_field:adminPolicy', :rows=>'0',
      :facet=>'on', :'facet.field'=>'apo_register_permissions_facet', :'facet.prefix'=>'workgroup:',
      :'facet.mincount'=>'1', :'facet.limit'=>'-1')
    facets = resp['facet_counts']['facet_fields']['apo_register_permissions_facet']
    priv_groups = facets.select { |v| v =~ /^workgroup:/ }
    directives += priv_groups.collect { |v| 
      ["Require privgroup #{v.split(/:/,2).last}", "WebAuthLdapPrivgroup #{v.split(/:/,2).last}"]
    }.flatten
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
    $stdout.print "Discovering PIDs..."
    index_log.info "Discovering PIDs..."
    pids = []
    if args[:query] == ':ALL:'
      pids = Dor::SearchService.risearch("select $object from <#ri> where $object <info:fedora/fedora-system:def/model#label> $label", :limit => '1000000', :timeout => -1)
    else
      q = args[:query] || '*:*'
      puts q
      start = 0
      resp = Dor::SearchService.gsearch(:q => q, :sort => 'id asc', :rows => 1000, :start => start, :fl => 'id')
      while resp['response']['docs'].length > 0
        pids += resp['response']['docs'].collect { |doc| doc['id'] }.flatten.select { |pid| pid =~ /^druid:/ }
        start += 1000
        $stdout.print "."
        resp = Dor::SearchService.gsearch(:q=>q, :rows => 1000, :start => start, :fl => 'id')
      end
      $stdout.puts
    end
    time = Time.now - start_time
    msg = "#{pids.length} PIDs discovered in #{[(time/3600).floor, (time/60 % 60).floor, (time % 60).floor].map{|t| t.to_s.rjust(2,'0')}.join(':')}"
    $stdout.puts msg
    index_log.info msg

    pbar = ProgressBar.new("Reindexing...", pids.length)
    errors = 0
    pids.each do |pid|
      begin
        index_log.debug "Indexing #{pid}"
        Dor::SearchService.reindex(pid)
      rescue Interrupt
        raise
      rescue Exception => e
        errors += 1
        index_log.warn("Error (#{errors}) indexing #{pid}")
        index_log.error("#{e.class}: #{e.message}")
        if errors == 3
          index_log.fatal("Too many errors. Exiting.")
          raise e 
        end
      end
      errors = 0
      pbar.inc(1)
    end
  end
  
end