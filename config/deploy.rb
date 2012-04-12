require "rvm/capistrano"                               # Load RVM's capistrano plugin.
require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'

set :stages, %W(dev testing prod)
set :default_stage, "development"
set :bundle_flags, "--quiet"
set :rvm_ruby_string, "1.8.7@argo"
set :rvm_type, :system

require 'capistrano/ext/multistage'

after "deploy:symlink", "argo:trust_rvmrc"
after "deploy:symlink", "argo:initialize_htaccess"
after "deploy:symlink", "argo:restart_indexer"

set :shared_children, %w(log config/certs config/environments config/database.yml config/solr.yml)

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {:auth_methods => %w(gssapi-with-mic publickey hostbased), :forward_agent => true}

set :destination, "/var/opt/home/lyberadmin"
set :application, "argo"

set :scm, :git
set :deploy_via, :copy # I got 99 problems, but AFS ain't one
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 10

set :deploy_to, "#{destination}/#{application}"

namespace :argo do
  task :trust_rvmrc do
    run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
  end
  
  task :initialize_htaccess do
    run "cd #{latest_release} && bundle exec rake RAILS_ENV=#{rails_env} argo:htaccess"
  end
  
  task :restart_indexer do
    dor_config_file = File.join(current_path,"config","environments","dor_#{rails_env}.rb")
    run "cd #{latest_release} && RAILS_ENV=#{rails_env} bundle exec dor-indexerd restart --dor-config #{dor_config_file} -o #{activemq_host}"
  end
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end