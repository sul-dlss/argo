server 'argo-dev.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'development'
set :bundle_without, %w{production test}.join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'
