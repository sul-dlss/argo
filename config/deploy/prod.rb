set :rails_env, "production"
set :activemq_host, "dor-prod.stanford.edu"
set :deployment_host, "lyberapps-prod.stanford.edu"
set :branch, "master"
set :bundle_without, [:deployment,:development,:test]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
