set :rails_env, "test"
set :activemq_host, "dor-test.stanford.edu"
set :deployment_host, "lyberapps-test.stanford.edu"
set :repository,  "."
set :branch, "master"
set :bundle_without, [:deployment,:development]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
