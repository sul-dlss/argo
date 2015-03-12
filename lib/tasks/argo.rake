require 'jettywrapper'
require 'json'
require 'rest_client'
require 'open-uri'
require 'fileutils'

desc "Get application version"
task :app_version do
  puts File.read(File.expand_path('../../../VERSION',__FILE__)).strip
end

def jettywrapper_load_config
  return Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../jetty'),:startup_wait => 200})
end

task :default => [:ci]

task :ci do
  ENV['RAILS_ENV'] = 'test'
  Rake::Task['argo:install'].invoke
  jetty_params = jettywrapper_load_config()
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['argo:repo:load'].invoke  # load 'em all!
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end

namespace :argo do
  desc "Install db, jetty (fedora/solr) and configs fresh"
  task :install => ['argo:jetty:clean', 'argo:jetty:config', 'db:setup', 'db:migrate', 'tmp:create'] do
    ['rails generate blacklight_hierarchy:install', 'rails generate argo:solr'].each{ |cmd|
      puts cmd
      system cmd
    }
  end

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

  namespace :jetty do
    WRAPPER_VERSION = "v7.1.0"

    desc "Get fresh hydra-jetty [target tag, default: #{WRAPPER_VERSION}] -- DELETES/REPLACES SOLR AND FEDORA"
    task :clean, [:target] do |t, args|
      args.with_defaults(:target=> WRAPPER_VERSION)
      jetty_params = jettywrapper_load_config()
      Jettywrapper.hydra_jetty_version = args[:target]
      Rake::Task['jetty:clean'].invoke
    end

    desc "Overwrite Solr configs and JARs"
    task :config => %w[argo:solr:config] do   # TODO: argo:fedora:config
    end
  end

  ## DEFAULTS
  solr_conf_dir     = 'solr_conf'
  fedora_conf_dir   = 'fedora_conf'
  fixtures_fileglob = "#{Rails.root}/#{solr_conf_dir}/data/*.json"
  fedora_fileglob   = "#{Rails.root}/#{fedora_conf_dir}/data/*.xml"
  live_solrxml_file = "jetty/solr/solr.xml"
  testcores = {'development' => 'development-core', 'test' => 'test-core'}  # name => path
  restcore_url = Blacklight.solr.options[:url] + "/admin/cores?action=STATUS&wt=json"
  realcores = []

  namespace :solr do
    ## HELPERS
    def xml_cores(file)
      res = Hash.new
      solrxml = Nokogiri.XML(File.read(file))
      solrxml.xpath('solr/cores/core').each do |core|
        res[core.attr('name')] = core.attr('instanceDir')
      end
      return res
    end
    def json_cores(url)
      return JSON.load(open(url))
    end

    desc "List cores from REST target, default: #{restcore_url}"
    task :cores, [:url] do |task, args|
      args.with_defaults(:url => restcore_url)
      url = args[:url]
      puts "Requesting #{url}"
      json = json_cores(url)
      json["status"].each do |k,v|
        puts "#{k} in #{v["name"]}"
      end
      realcores = json["status"]
    end

    desc "Read cores from solr.xml file, default: #{live_solrxml_file}"
    task :xmlcores, [:solrxml] do |task, args|
      args.with_defaults(:solrxml => live_solrxml_file)
      xml_cores(args[:solrxml]).each do |k,v|
        puts "#{k} in #{v}"
      end
    end

    desc "Clear all data from running core(s), default: [list from :cores]"
    task :nuke, [:cores] => :cores do |task, args|
      args.with_defaults(:cores => realcores.keys)
      args[:cores].each do |core|
        url = Blacklight.solr.options[:url] + "/" + core + '/update?commit=true'
        puts "Completely delete all data in #{core} at:\n  #{url}\nAre you sure? [y/n]"
        input = STDIN.gets.strip
        if input == 'y'
          RestClient.post url, '<delete><query>*:*</query></delete>', :content_type => 'text/xml; charset=utf-8'
          puts "Nuked #{core}"
        else
          puts "Skipping #{core}"
        end
      end
    end

    desc "Load Solr data into running core(s), default: '#{fixtures_fileglob}' ==> [list from :cores] ## note quotes around glob"
    task :load, [:glob, :cores] => :cores do |task, args|
      args.with_defaults(:glob => fixtures_fileglob, :cores => realcores.keys)
      docs = []
      counts = Hash.new{ |h,k| 0 }
      Dir.glob(args[:glob]).each do |file|
        reply = JSON.parse(IO.read(file))
        reply["response"]["docs"].each do |doc|
          puts file + " " + doc["id"]
          doc.delete('_version_')   # we can't post to an empty core while specifying that we are updating a given version!
          docs << { "doc" => doc }
          counts[file] = counts[file] + 1
        end
      end
      puts counts
      payload = "{\n" + docs.collect{|x| '"add": ' + JSON.pretty_generate(x)}.join(",\n") + "\n}"

      IO.write("temp.json", payload)
      cores = args[:cores].is_a?(String) ? args[:cores].split(' ') : args[:cores] # make sure we got an array
      cores.each do |core|
        url = Blacklight.solr.options[:url] + "/" + core + '/update?commit=true'
        puts "Adding #{docs.count} docs from #{counts.count} file(s) to #{url}"
        RestClient.post url, payload, :content_type => "application/json"
      end
    end

    desc "Configure Solr root and core(s) from source dir, default: #{solr_conf_dir}"
    task :config, [:dir] => ['argo:solr:config_root', 'argo:solr:config_cores'] do |task, args|
    end

    desc "Configure Solr root from source dir, default: #{solr_conf_dir}"
    task :config_root, [:dir] do |task, args|
      args.with_defaults(:dir => solr_conf_dir)
      cp("#{args[:dir]}/solr.xml", 'jetty/solr/', verbose: true)
    end

    desc "Copies configs to matching local Solr instanceDir(s), default: #{solr_conf_dir} ==> #{testcores.keys.sort}"
    task :config_cores, [:dir, :cores] do |task, args|
      args.with_defaults(:dir => solr_conf_dir, :cores => testcores.keys.sort)
      args[:cores].each do |core|
        instancedir = testcores[core] || core
        puts "travis_fold:start:argo-config_cores-#{core}\r" if ENV['TRAVIS'] == 'true'
        puts "**** #{core} in #{instancedir}"
        FileUtils.mkdir_p("jetty/solr/#{instancedir}/conf/", verbose: true)
        FileList["#{args[:dir]}/conf/*"].each do |f|
          cp(f, "jetty/solr/#{instancedir}/conf/", verbose: true)
        end
        ## Mac OSX sed requires -i bak file
        ## puts "sed -i.bak -e 's/core1/#{core}/g;' jetty/solr/#{instancedir}/conf/solrconfig.xml"   # tweak solrconfig
        ## system("sed -i.bak -e 's/core1/#{core}/g;' jetty/solr/#{instancedir}/conf/solrconfig.xml")
        propfile = "jetty/solr/#{instancedir}/core.properties"
        open(propfile, 'w') { |f|
          f.puts "name=#{core}"
        }
        puts "Added #{propfile}"
        puts "travis_fold:end:argo-config_cores-#{core}\r" if ENV['TRAVIS'] == 'true'
      end
    end

  end # :solr

  namespace :repo do
    desc "Load XML file(s) into repo (fedora and solr), default: '#{fedora_fileglob}' ## note quotes around glob"
    task :load, [:glob] do |task, args|
      puts "travis_fold:start:script.argo-repo-load\r" if ENV['TRAVIS'] == 'true'
      args.with_defaults(:glob => fedora_fileglob)
      docs   = []
      errors = []
      i = 0
      Dir.glob(args[:glob]).each do |file|
        puts "** #{i=i+1} ** repo:load foxml=#{file}"
        begin
          Rake::Task['repo:load'].invoke("foxml=#{file}")
        rescue StandardError => e
          puts STDERR.puts "ERROR loading #{file}:\n  #{e.message}"
          errors << file
        end
        Rake::Task['repo:load'].reenable
      end
      puts "Loaded #{i-errors.size()} of #{i} files successfully"
      puts "travis_fold:start:script.argo-repo-load\r" if ENV['TRAVIS'] == 'true'
    end
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

    directives += (File.readlines(File.join(Rails.root, 'config/default_htaccess_directives')) || [])

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

    desc "Reindex all (or a subset) of DOR objects in Solr"
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
