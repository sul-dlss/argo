server 'argo-prod-a.stanford.edu', user: 'lyberadmin', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :deploy_to, '/opt/app/lyberadmin/argo'
set :bundle_without, %w(deployment development test).join(' ')

set :delayed_job_workers, 12
