require 'jettywrapper'
desc "Get application version"
task :app_version do
  puts File.read(File.expand_path('../../../VERSION',__FILE__)).strip
end  
task :ci do
  ENV['RAILS_ENV'] = 'test'
  Rake::Task['db:migrate'].invoke
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../jetty'),:startup_wait => 200})
  error = Jettywrapper.wrap(jetty_params) do  
      system 'rspec'
    end
    raise "test failures: #{error}" if error
end
namespace :argo do
  desc "Bump Argo's version number before release"
  task :bump_version, [:level] do |t, args|
    levels = ['major','minor','patch','rc']
    version_file = File.expand_path('../../../VERSION',__FILE__)
    version = File.read(version_file)
    version = version.split(/\./)
    index = levels.index(args[:level] || (version.length == 4 ? 'rc' : 'patch'))
    if version.length == 4 and index < 3
      version.pop
    end
    if index == 3
      rc = version.length == 4 ? version.pop : 'rc0'
      rc.sub!(/^rc(\d+)$/) { |m| "rc#{$1.to_i+1}" }
      version << rc
      puts version.inspect
    else
      version[index] = version[index].to_i+1
      (index+1).upto(2) { |i| version[i] = '0' }
    end
    version = version.join('.')
    File.open(version_file,'w') { |f| f.write(version) }
    $stderr.puts "Version bumped to #{version}"
  end

  desc "Update the .htaccess file from indexed APOs"
  task :htaccess => :environment do
    directives = [

      'AuthType WebAuth',
      'Require privgroup dlss:argo-access',
      'WebAuthLdapAttribute suAffiliation',
      'WebAuthLdapAttribute displayName',
      'WebAuthLdapAttribute mail',
    ]

    directives += File.readlines(File.join(Rails.root, 'config/default_htaccess_directives')) rescue nil

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

    desc "Update completed/archived workflow counts"
    task :update_archive_counts => :environment do |t|
      Dor.find_all('objectType_facet:workflow').each do |wf|
        wf.update_index
      end
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
        dor_pids = []
        Dor::SearchService.iterate_over_pids(:in_groups_of => 1000, :mode => :group) do |chunk|
          dor_pids += chunk
          $stderr.print "."
        end
        $stdout.puts
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
