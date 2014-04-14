set :rails_env, "development"
set :activemq_host, "dor-dev.stanford.edu"
set :deployment_host, "argo-dev.stanford.edu"
set :repository,  "git@github.com:sul-dlss/argo.git"
set :branch, "develop"
set :bundle_without, [:deployment,:production]
set :rvm_ruby_string, "1.9.3"
set :destination, "/home/lyberadmin"
set :application, "argo"
set :deploy_to, "#{destination}/#{application}"

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
