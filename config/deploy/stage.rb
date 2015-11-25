server 'argo-stage-b.stanford.edu', user: 'lyberadmin', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'staging'
set :bundle_without, %w(test development).join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'

set :delayed_job_workers, 2
