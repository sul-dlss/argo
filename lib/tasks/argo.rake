require 'jettywrapper'
require 'json'
require 'rest_client'
require 'open-uri'
require 'fileutils'
require 'retries'

desc 'Get application version'
task :app_version do
  puts File.read(File.expand_path('../../../VERSION', __FILE__)).strip
end

def jettywrapper_load_config
  Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../jetty'), :startup_wait => 200})
end

task :default => [:ci]

task :ci do
  if Rails.env.test?
    Rake::Task['argo:install'].invoke
    jetty_params = jettywrapper_load_config()
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task['argo:repo:load'].invoke  # load 'em all!
      Rake::Task['spec'].invoke
    end
    raise "test failures: #{error}" if error
  else
    system('RAILS_ENV=test rake ci')
  end
end

if ['test', 'development'].include? ENV['RAILS_ENV']
  require 'rspec/core/rake_task'

  # Larger integration/acceptance style tests (take several minutes to complete)
  RSpec::Core::RakeTask.new(:integration_tests) do |spec|
    spec.pattern = 'spec/integration/**/*_spec.rb'
  end
end

namespace :argo do
  desc 'Install db, jetty (fedora/solr) and configs fresh'
  task :install => ['argo:jetty:clean', 'argo:jetty:config', 'db:setup', 'db:migrate'] do
    puts 'Installed Argo'
  end

  desc "Bump Argo's version number before release"
  task :bump_version, [:level] do |t, args|
    levels = %w(major minor patch rc)
    version_file = File.expand_path('../../../VERSION', __FILE__)
    version = File.read(version_file)
    version = version.split(/\./)
    index = levels.index(args[:level] || (version.length == 4 ? 'rc' : 'patch'))
    version.pop if version.length == 4 && index < 3
    if index == 3
      rc = version.length == 4 ? version.pop : 'rc0'
      rc.sub!(/^rc(\d+)$/) { |m| "rc#{$1.to_i + 1}" }
      version << rc
      puts version.inspect
    else
      version[index] = version[index].to_i + 1
      (index + 1).upto(2) { |i| version[i] = '0' }
    end
    version = version.join('.')
    File.open(version_file, 'w') { |f| f.write(version) }
    $stderr.puts "Version bumped to #{version}"
  end

  namespace :jetty do
    WRAPPER_VERSION = 'v7.2.0' # the most recent Fedora 3.x release (Fedora 3.8.1 and Solr 4.10.2)

    desc "Get fresh hydra-jetty [target tag, default: #{WRAPPER_VERSION}] -- DELETES/REPLACES SOLR AND FEDORA"
    task :clean, [:target] do |t, args|
      args.with_defaults(:target => WRAPPER_VERSION)
      jettywrapper_load_config()
      Jettywrapper.hydra_jetty_version = args[:target]
      Rake::Task['jetty:clean'].invoke
    end

    desc 'Overwrite Solr configs and JARs'
    task :config => %w(argo:solr:config) do   # TODO: argo:fedora:config
    end
  end  # :jetty

  ## DEFAULTS
  solr_conf_dir     = 'solr_conf'
  fixtures_fileglob = "#{Rails.root}/#{solr_conf_dir}/data/*.json"
  fedora_files      = File.foreach(File.join(File.expand_path('../../../fedora_conf/data/', __FILE__), 'load_order')).to_a
  live_solrxml_file = 'jetty/solr/solr.xml'
  testcores = {'development' => 'development-core', 'test' => 'test-core'}  # name => path
  restcore_url = Blacklight.solr.options[:url] + '/admin/cores?action=STATUS&wt=json'
  realcores = []

  namespace :solr do
    ## HELPERS
    def xml_cores(file)
      res = {}
      solrxml = Nokogiri.XML(File.read(file))
      solrxml.xpath('solr/cores/core').each do |core|
        res[core.attr('name')] = core.attr('instanceDir')
      end
      res
    end

    def json_cores(url)
      JSON.load(open(url))
    end

    desc "List cores from REST target, default: #{restcore_url}"
    task :cores, [:url] do |task, args|
      args.with_defaults(:url => restcore_url)
      url = args[:url]
      puts "Requesting #{url}"
      json = json_cores(url)
      json['status'].each do |k, v|
        puts "#{k} in #{v['name']}"
      end
      realcores = json['status']
    end

    desc "Read cores from solr.xml file, default: #{live_solrxml_file}"
    task :xmlcores, [:solrxml] do |task, args|
      args.with_defaults(:solrxml => live_solrxml_file)
      xml_cores(args[:solrxml]).each do |k, v|
        puts "#{k} in #{v}"
      end
    end

    desc 'Clear all data from running core(s), default: [list from :cores]'
    task :nuke, [:cores] => :cores do |task, args|
      args.with_defaults(:cores => realcores.keys)
      args[:cores].each do |core|
        url = Blacklight.solr.options[:url] + '/' + core + '/update?commit=true'
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
      counts = Hash.new{ |h, k| 0 }
      Dir.glob(args[:glob]).each do |file|
        reply = JSON.parse(IO.read(file))
        reply['response']['docs'].each do |doc|
          puts file + ' ' + doc['id']
          doc.delete('_version_')   # we can't post to an empty core while specifying that we are updating a given version!
          docs << { 'doc' => doc }
          counts[file] = counts[file] + 1
        end
      end
      puts counts
      payload = "{\n" + docs.collect{|x| '"add": ' + JSON.pretty_generate(x)}.join(",\n") + "\n}"

      IO.write('temp.json', payload)
      cores = args[:cores].is_a?(String) ? args[:cores].split(' ') : args[:cores] # make sure we got an array
      cores.each do |core|
        url = Blacklight.solr.options[:url] + '/' + core + '/update?commit=true'
        puts "Adding #{docs.count} docs from #{counts.count} file(s) to #{url}"
        RestClient.post url, payload, :content_type => 'application/json'
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
    desc "Load XML file(s) into repo (fedora and solr), default: contents of 'load_order' file. With a glob: rake argo:repo:load[fedora_conf/data/*.xml]"
    task :load, [:glob] do |task, args|
      puts "travis_fold:start:argo-repo-load\r" if ENV['TRAVIS'] == 'true'

      file_list = []
      if args.key?(:glob)
        file_list = glob_files(args[:glob])
      else
        puts 'No file glob was specified so file order and inclusion is determined by the load_order file'
        file_list = load_order_files(fedora_files)
      end

      errors = []
      i = 0

      file_list.each do |file|
        i += 1

        ENV['foxml'] = file
        handler = proc do |e, attempt_number, total_delay|
          puts STDERR.puts "ERROR loading #{file}:\n#{e.message}\n#{e.backtrace.join "\n"}"
          errors << file
        end
        with_retries(:max_tries => 3, :handler => handler, :rescue => [StandardError]) { |attempt|
          puts "** File #{i}, Try #{attempt} ** repo:load foxml=#{file}"
          # Invoke the ActiveFedora gem's rake task
          Rake::Task['repo:load'].reenable
          Rake::Task['repo:load'].invoke
        }
      end
      Rake::Task['repo:load'].reenable      # other things might want to load, too
      ENV.delete('foxml') if ENV['foxml']   # avoid ENV contamination
      puts 'Done loading repo files'
      puts "ERROR in #{errors.size()} of #{i} files" if errors.size() > 0
#     puts "Loaded #{i-errors.size()} of #{i} files successfully"   # these won't be true until repo:load actually fails unless successful
      puts "travis_fold:end:argo-repo-load\r" if ENV['TRAVIS'] == 'true'
    end
  end # :repo

  # some helper methods
  def apo_field_default
    'apo_register_permissions_ssim'
  end

  def get_workgroups_facet(apo_field = nil)
    apo_field = apo_field_default() if apo_field.nil?
    resp = Dor::SearchService.query('objectType_ssim:adminPolicy', :rows => 0,
      :facets => { :fields => [apo_field] },
      :'facet.prefix'   => 'workgroup:',
      :'facet.mincount' => 1,
      :'facet.limit'    => -1 )
    resp.facets.find { |f| f.name == apo_field }
  end

  def load_order_files(fedora_files)
    data_path = File.expand_path('../../../fedora_conf/data/', __FILE__)
    fedora_files.delete_if {|f| f.strip.empty? }
    fedora_files.map {|f| File.join(data_path, f.strip) }
  end

  def glob_files(glob_expression)
    Dir.glob(glob_expression)
  end

  desc "List APO workgroups from Solr (#{apo_field_default()})"
  task :workgroups => :environment do
    facet = get_workgroups_facet()
    puts "#{facet.items.count} Workgroups:\n#{facet.items.collect(&:value).join(%(\n))}"
  end

  # the .htaccess file lists the workgroups that we recognize as relevant to argo.
  # if a user is in a workgroup, and that workgroup is listed in the .htaccess file,
  # the name of the workgroup will be in a list of workgroups for the user, passed along
  # with other webauth info in the request headers.  we use the list of workgroups a user is
  # in (as well as the user's sunetid) to determine what they can see and do in argo.
  # NOTE: at present (2015-11-06), this rake task is run regularly by a cron job, so that
  # the .htaccess file keeps up with workgroup names as listed on APOs in use in argo.
  desc 'Update the .htaccess file from indexed APOs'
  task :htaccess => :environment do
    directives = ['AuthType WebAuth',
                  'Require privgroup dlss:argo-access',
                  'WebAuthLdapAttribute suAffiliation',
                  'WebAuthLdapAttribute displayName',
                  'WebAuthLdapAttribute mail']

    directives += (File.readlines(File.join(Rails.root, 'config/default_htaccess_directives')) || [])
    facet = get_workgroups_facet()
    unless facet.nil?
      facets = facet.items.collect(&:value)

      priv_groups = facets.select { |v| v =~ /^workgroup:/ }
      priv_groups += (ADMIN_GROUPS + VIEWER_GROUPS + MANAGER_GROUPS) # we know that we always want these built-in groups to be part of .htaccess
      priv_groups.uniq! # no need to repeat ourselves (mostly there in case the builtin groups are already listed in APOs)

      directives += priv_groups.collect { |v|
        ["Require privgroup #{v.split(/:/, 2).last}", "WebAuthLdapPrivgroup #{v.split(/:/, 2).last}"]
      }.flatten

      File.open(File.join(Rails.root, 'public/.htaccess'), 'w') do |htaccess|
        htaccess.puts directives.sort.join("\n")
      end
      File.unlink('public/auth/.htaccess') if File.exist?('public/auth/.htaccess')
    end
  end  # :htaccess

  desc 'Update completed/archived workflow counts'
  task :update_archive_counts => :environment do |t|
    Dor.find_all('objectType_ssim:workflow').each(&:update_index)
  end

  desc 'Reindex all DOR objects to Solr'
  task :reindex_all => [:environment] do |t, args|
    Argo::BulkReindexer.reindex_all
  end
end     # :argo
