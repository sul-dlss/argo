# frozen_string_literal: true

server 'argo-stage-a.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]
server 'argo-stage-b.stanford.edu', user: 'lyberadmin', roles: %w[web db app worker]
