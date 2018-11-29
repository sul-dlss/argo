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
    Rake::Task['argo:repo:load'].invoke # load 'em all!
    Rake::Task['spec'].invoke
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
  require 'rspec/core/rake_task'

  desc 'Larger integration/acceptance style tests (take several minutes to complete)'
  RSpec::Core::RakeTask.new(:integration_tests) do |spec|
    spec.pattern = 'spec/integration/**/*_spec.rb'
  end

  fedora_files = File.foreach(File.join(File.expand_path('../../../fedora_conf/data/', __FILE__), 'load_order')).to_a

  namespace :argo do
    desc 'Install db'
    task install: ['db:migrate'] do
      puts 'Installed Argo'
    end

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
          pid = "druid:#{File.basename(file, '.xml')}"
          with_retries(max_tries: 3, handler: handler, rescue: [StandardError]) { |attempt|
            puts "** File #{i}, Try #{attempt} ** file: #{file}"
            ActiveFedora::FixtureLoader.import_to_fedora(file, pid)
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
