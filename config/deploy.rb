require "rvm/capistrano"                               # Load RVM's capistrano plugin.
require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'

set :stages, %W(dev testing prod)
set :default_stage, "development"
set :bundle_flags, "--quiet"
set :rvm_ruby_string, "1.9.3"
set :rvm_type, :system

require 'capistrano/ext/multistage'

after "deploy:create_symlink", "argo:trust_rvmrc"
after "deploy:create_symlink", "argo:initialize_htaccess"
after "deploy:create_symlink", "argo:restart_indexer"
after "deploy", "deploy:migrate"

set :shared_children, %w(log config/certs config/environments config/database.yml config/solr.yml config/default_htaccess_directives)

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {:auth_methods => %w(gssapi-with-mic publickey hostbased), :forward_agent => true}


set :scm, :git
set :deploy_via, :copy # I got 99 problems, but AFS ain't one
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 10



namespace :argo do
  task :trust_rvmrc do
    run "/usr/local/rvm/bin/rvm rvmrc trust #{latest_release}"
  end
  
  task :initialize_htaccess do
    run "cd #{latest_release} && bundle exec rake RAILS_ENV=#{rails_env} argo:htaccess"
  end
end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
