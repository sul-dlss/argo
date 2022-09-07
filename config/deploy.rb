# frozen_string_literal: true

set :application, 'argo'
set :repo_url, 'https://github.com/sul-dlss/argo.git'

# Default branch is :main
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/opt/app/lyberadmin/argo'

set :rails_env, 'production'
set :bundle_without, %w[deployment test development].join(' ')

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w[config/database.yml config/secrets.yml config/blacklight.yml config/honeybadger.yml]

# Default value for linked_dirs is []
set :linked_dirs, %w[log config/settings tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

set :sidekiq_systemd_role, :worker
set :sidekiq_systemd_use_hooks, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, fetch(:stage)

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'

# configure capistrano-rails to work with propshaft instead of sprockets
# (we don't have public/assets/.sprockets-manifest* or public/assets/manifest*.*)
set :assets_manifests, lambda {
  [release_path.join('public', fetch(:assets_prefix), '.manifest.json')]
}
