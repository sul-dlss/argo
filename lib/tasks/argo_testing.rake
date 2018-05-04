require 'fileutils'
require 'retries'

def load_order_files(fedora_files)
  data_path = File.expand_path('../../../fedora_conf/data/', __FILE__)
  fedora_files.delete_if { |f| f.strip.empty? }
  fedora_files.map { |f| File.join(data_path, f.strip) }
end

task default: :ci_w_rubocop

desc 'run specs and rubocop (like we want ci to do)'
task ci_w_rubocop: [:ci, :rubocop]

desc 'run specs after loading up solr, fedora, etc.'
task :ci do
  if Rails.env.test?
    Rake::Task['argo:install'].invoke
    jetty_params = jettywrapper_load_config()
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task['argo:repo:load'].invoke # load 'em all!
      Rake::Task['spec'].invoke
    end
    raise "test failures: #{error}" if error
  else
    system('RAILS_ENV=test rake ci')
  end
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run rubocop'
  task :rubocop do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

if ['test', 'development'].include? Rails.env
  require 'jettywrapper'
  Jettywrapper.hydra_jetty_version = 'v7.3.0' # this keeps us on fedora 3, hydra-jetty v8.x moves to fedora 4.
  def jettywrapper_load_config
    Jettywrapper.load_config.merge(jetty_home: File.expand_path(File.dirname(__FILE__) + '../../../jetty'), startup_wait: 200)
  end

  require 'rspec/core/rake_task'

  desc 'Larger integration/acceptance style tests (take several minutes to complete)'
  RSpec::Core::RakeTask.new(:integration_tests) do |spec|
    spec.pattern = 'spec/integration/**/*_spec.rb'
  end

  fedora_files = File.foreach(File.join(File.expand_path('../../../fedora_conf/data/', __FILE__), 'load_order')).to_a

  namespace :argo do
    desc 'Install db, jetty (fedora/solr) and configs fresh'
    task install: ['argo:jetty:clean', 'argo:jetty:config', 'db:migrate'] do
      puts 'Installed Argo'
    end

    namespace :jetty do
      WRAPPER_VERSION = 'v7.3.0' # the most recent Fedora 3.x release (Fedora 3.8.1 and Solr 4.10.4)

      desc "Get fresh hydra-jetty [target tag, default: #{WRAPPER_VERSION}] -- DELETES/REPLACES SOLR AND FEDORA"
      task :clean, [:target] do |t, args|
        args.with_defaults(target: WRAPPER_VERSION)
        jettywrapper_load_config()
        Jettywrapper.hydra_jetty_version = args[:target]
        Rake::Task['jetty:clean'].invoke
      end

      desc 'Overwrite Solr configs and JARs'
      task config: %w(argo:solr:config) do # TODO: argo:fedora:config
      end
    end

    solr_conf_dir = 'solr_conf'

    namespace :solr do
      desc "Configure Solr root and core(s) from source dir, default: #{solr_conf_dir}"
      task :config, [:dir] => ['argo:solr:config_root', 'argo:solr:config_cores'] do |task, args|
      end

      desc "Configure Solr root from source dir, default: #{solr_conf_dir}"
      task :config_root, [:dir] do |task, args|
        args.with_defaults(dir: solr_conf_dir)
        cp("#{args[:dir]}/solr.xml", 'jetty/solr/', verbose: true)
      end

      testcores = { 'development' => 'development-core', 'test' => 'test-core' } # name => path

      desc "Copies configs to matching local Solr instanceDir(s), default: #{solr_conf_dir} ==> #{testcores.keys.sort}"
      task :config_cores, [:dir, :cores] do |task, args|
        args.with_defaults(dir: solr_conf_dir, cores: testcores.keys.sort)
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
      task :load, [:glob] => :environment do |task, args|
        puts "travis_fold:start:argo-repo-load\r" if ENV['TRAVIS'] == 'true'

        file_list = []
        if args.key?(:glob)
          file_list = Dir.glob(args[:glob])
        else
          puts 'No file glob was specified so file order and inclusion is determined by the load_order file'
          file_list = load_order_files(fedora_files)
        end

        errors = []
        i = 0

        file_list.each do |file|
          i += 1

          handler = proc do |e, attempt_number, total_delay|
            puts STDERR.puts "ERROR loading #{file}:\n#{e.message}\n#{e.backtrace.join "\n"}"
            errors << file
          end
          with_retries(max_tries: 3, handler: handler, rescue: [StandardError]) { |attempt|
            puts "** File #{i}, Try #{attempt} ** file: #{file}"
            pid = ActiveFedora::FixtureLoader.import_to_fedora(file)
            ActiveFedora::FixtureLoader.index(pid)
          }
        end
        puts 'Done loading repo files'
        puts "ERROR in #{errors.size()} of #{i} files" if errors.size() > 0
        #     puts "Loaded #{i-errors.size()} of #{i} files successfully"   # these won't be true until repo:load actually fails unless successful
        puts "travis_fold:end:argo-repo-load\r" if ENV['TRAVIS'] == 'true'
      end
    end # :repo
  end # :argo

end # if test or dev env
