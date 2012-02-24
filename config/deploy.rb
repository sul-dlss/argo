$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                               # Load RVM's capistrano plugin.
require 'net/ssh/kerberos'
require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'

before "deploy:setup", "dlss:create_gemset", "dlss:set_shared_children"

set :bundle_flags, ""

set :deployment_host, "lyberapps-dev.stanford.edu"
set :branch, "develop"
set :bundle_without, [:local,:production]
set :rvm_ruby_string, "1.8.7@argo"

task :testing do
  set :deployment_host, "lyberapps-test.stanford.edu"
  set :branch, "master"
  set :bundle_without, [:local,:development]
end

task :production do
  set :deployment_host, "lyberapps-prod.stanford.edu"
  set :branch, "master"
  set :bundle_without, [:local,:development,:test]
end

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true

set :user, "lyberadmin" 
set :runner, "lyberadmin"
set :ssh_options, {:auth_methods => %w(gssapi-with-mic publickey hostbased), :forward_agent => true}

set :destination, "/home/lyberadmin"
set :application, "argo"

set :scm, :git
set :repository,  "ssh://cardinal.stanford.edu/afs/ir/dev/dlss/git/lyberteam/argo.git"
set :deploy_via, :copy # I got 99 problems, but AFS ain't one
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 10

set :deploy_to, "#{destination}/#{application}"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end