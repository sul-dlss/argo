server 'argo-stage-b.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "staging"
set :bundle_without, %w{production development}.join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'

