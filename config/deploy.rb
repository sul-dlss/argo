lock '3.4.0'

set :application, 'argo'
set :repo_url, 'https://github.com/sul-dlss/argo.git'

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# TODO:  ask for user, should know what the name of the app is, should be able to build deploy_to from those
# TODO:  prompt for server name and use that to build hostname (based on app name)
# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/lyberadmin/argo'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w(config/database.yml config/secrets.yml config/blacklight.yml config/default_htaccess_directives)

# Default value for linked_dirs is []
set :linked_dirs, %w(log config/certs config/settings tmp/pids tmp/cache tmp/sockets vendor/bundle public/system)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

before 'deploy:publishing', 'squash:write_revision'

namespace :deploy do
  # it's necessary to run the 'argo:htaccess' rake task after restarting, because
  # the public folder (which contains the generated .htaccess file) is committed
  # in argo's git repo, and so a fresh copy (without the generated .htaccess file)
  # will get written with each deployment.  the .htaccess file with the correct
  # list of workgroups is required for argo's permissions checking mechanism to function.
  after :restart, :initialize_htaccess do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'argo:htaccess'
        end
      end
    end
  end

  # execute the eye script located in the deployed argo's bin directory, since
  # eye may not be installed system-wide.  load the delayed_job_workers.eye config,
  # which should monitor workers for memory consumption (restarting them individually
  # if and when they exceed the configured threshold).
  after :restart, :load_eye_dj_config do
    on roles(:app) do
      within release_path do
        # :delayed_job_workers is set by the env specific cap configs.  it won't
        # yet be set when this task is defined (though it will be by the time it's
        # executed).
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          # quit first to make sure the new config is loaded
          execute :'./bin/eye', :quit

          # avoid spaces in the command name, see http://capistranorb.com/documentation/getting-started/tasks/
          execute :'./bin/eye', :load, :'config/eye/delayed_job_workers.eye'
        end
      end
    end
  end
end
