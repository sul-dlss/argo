# frozen_string_literal: true

server "argo-qa-a.stanford.edu", user: "lyberadmin", roles: %w[web db app worker]
server "argo-qa-b.stanford.edu", user: "lyberadmin", roles: %w[web db app worker]

Capistrano::OneTimeKey.generate_one_time_key!
