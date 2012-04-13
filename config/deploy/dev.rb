set :rails_env, "development"
set :activemq_host, "dor-dev.stanford.edu"
set :deployment_host, "lyberapps-dev.stanford.edu"
set :repository,  "."
set :branch, "develop"
set :bundle_without, [:deployment,:production]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
