# frozen_string_literal: true

server 'argo-prod-01.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]
server 'argo-prod-02.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]

Capistrano::OneTimeKey.generate_one_time_key!

# During the early 2022 work cycle, Andrew would like to ship release notes to users in advance of deploys to prod
before 'deploy:starting', :andrew_approval do
  ask :confirmation, 'Did Andrew approve this deployment to prod? If so, type "Andrew" to confirm'

  raise 'Canceling the deployment' unless fetch(:confirmation) == 'Andrew'
end
