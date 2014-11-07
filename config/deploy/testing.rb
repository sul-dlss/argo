server 'argo-test.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "testing"
set :bundle_without, %w{production development}.join(' ')

set :branch, :develop
