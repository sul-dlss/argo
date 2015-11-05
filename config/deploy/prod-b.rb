server 'argo-prod-b.stanford.edu', user: 'lyberadmin', roles: %w{web db app}

## argo-prod-b will be used to generate a new (dev) Solr index from PRODUCTION fedora.
## Therefore it is not for running tests or poking around the interface!

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :deploy_to, '/opt/app/lyberadmin/argo'
