set :rails_env, "test"
set :deployment_host, "lyberapps-test.stanford.edu"
set :branch, "master"
set :bundle_without, [:deployment,:development]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
