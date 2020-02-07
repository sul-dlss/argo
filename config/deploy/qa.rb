# frozen_string_literal: true

server 'argo-qa-a.stanford.edu', user: 'lyberadmin', roles: %w(web db app)
server 'argo-qa-b.stanford.edu', user: 'lyberadmin', roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'
set :bundle_without, %w(deployment test development).join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'

set :delayed_job_workers, 4
