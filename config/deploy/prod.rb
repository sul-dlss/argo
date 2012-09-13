set :rails_env, "production"
set :activemq_host, "dor-prod.stanford.edu"
set :deployment_host, "argo-prod.stanford.edu"
set :repository,  "git@github.com:sul-dlss/argo.git"
set :branch, "master"
set :bundle_without, [:deployment,:development,:test]
set :destination, "/home/lyberadmin"
set :application, "argo"
set :deploy_to, "#{destination}/#{application}"

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
