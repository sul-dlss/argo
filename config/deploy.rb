require 'bundler/capistrano'
require 'net/ssh'
require 'net/ssh/kerberos'

default_run_options[:pty] = true # Must be set for the password prompt from git to work

task :development do
  role :web, "lyberapps-dev.stanford.edu"
  role :app, "lyberapps-dev.stanford.edu"
  role :db,  "lyberapps-dev.stanford.edu", :primary => true
  set :branch, "develop"
end

task :testing do
  role :web, "lyberapps-test.stanford.edu"
  role :app, "lyberapps-test.stanford.edu"
  role :db,  "lyberapps-test.stanford.edu", :primary => true
  set :branch, "master"
end

task :production do
  role :web, "lyberapps-prod.stanford.edu"
  role :app, "lyberapps-prod.stanford.edu"
  role :db,  "lyberapps-prod.stanford.edu", :primary => true
  set :branch, "master"
end

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
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end