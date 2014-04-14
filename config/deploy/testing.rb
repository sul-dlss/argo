set :rails_env, "production"
set :activemq_host, "dor-test.stanford.edu"
set :deployment_host, "argo-test.stanford.edu"
set :repository,  "https://github.com/sul-dlss/argo.git"
set :branch, "develop"
set :deploy_via, 'copy'
set :bundle_without, [:deployment,:development]
set :destination, "/home/lyberadmin"
set :application, "argo"
set :deploy_to, "#{destination}/#{application}"

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
