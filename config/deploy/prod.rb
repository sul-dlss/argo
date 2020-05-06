# frozen_string_literal: true

server 'argo-prod-01.stanford.edu', user: 'lyberadmin', roles: %w[web db app]
server 'argo-prod-02.stanford.edu', user: 'lyberadmin', roles: %w[web db app]

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :deploy_to, '/opt/app/lyberadmin/argo'
set :bundle_without, %w[deployment development test].join(' ')

set :delayed_job_workers, 12
