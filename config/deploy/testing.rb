set :rails_env, "test"
set :activemq_host, "dor-test.stanford.edu"
set :deployment_host, "lyberapps-test.stanford.edu"
set :repository,  "."
set :branch, "develop"
set :bundle_without, [:deployment,:development]
set :destination, "/var/opt/home/lyberadmin"
set :application, "argo"
set :deploy_to, "#{destination}/#{application}"

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
