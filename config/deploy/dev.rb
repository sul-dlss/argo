server 'argo-dev.stanford.edu', user: 'lyberadmin', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'development'
set :bundle_without, %w(deployment production test).join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'

set :delayed_job_workers, 2 # NOTE: should be >= 2, see config/eye/delayed_job_workers.eye for explanation
