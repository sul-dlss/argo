# frozen_string_literal: true

server 'argo-stage-a.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]
server 'argo-stage-b.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'staging'
set :bundle_without, %w[deployment test development].join(' ')

set :deploy_to, '/opt/app/lyberadmin/argo'
