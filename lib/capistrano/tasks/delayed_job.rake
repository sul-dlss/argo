# frozen_string_literal: true

namespace :delayed_job do
  # NOTE: For below tasks, :delayed_job_workers is set by the env-specific cap
  # configs. it won't yet be set when this task is defined though it will be by
  # the time it's executed.

  # reload the delayed_job_workers.eye config, which should monitor workers for
  # memory consumption (restarting them individually if and when they exceed the
  # configured threshold).
  desc 'Quit and re-load the eye daemon that manages delayed_job workers'
  task :reload do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          # quit first to make sure the new config is loaded
          execute :'./bin/eye', :quit, raise_on_non_zero_exit: false
          # avoid spaces in the command name, see http://capistranorb.com/documentation/getting-started/tasks/
          execute :'./bin/eye', :load, :'config/eye/delayed_job_workers.eye'
        end
      end
    end
  end

  desc 'Start delayed_job workers via eye'
  task :start do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          execute :'./bin/eye', :start, :delayed_job
        end
      end
    end
  end

  desc 'Stop delayed_job workers via eye'
  task :stop do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          execute :'./bin/eye', :stop, :delayed_job
        end
      end
    end
  end

  desc 'Restart delayed_job_workers via eye'
  task :restart do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          execute :'./bin/eye', :restart, :delayed_job
        end
      end
    end
  end

  desc 'Show status of delayed_job workers via eye'
  task :status do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env), argo_delayed_job_worker_count: fetch(:delayed_job_workers) do
          execute :'./bin/eye', :info, :delayed_job, raise_on_non_zero_exit: false
        end
      end
    end
  end
end

# These hooks after used in both deployments and rollbacks
after 'deploy:starting', 'delayed_job:reload'
after 'deploy:started', 'delayed_job:stop'
before 'deploy:published', 'delayed_job:start'
before 'deploy:finished', 'delayed_job:status'

# This hook is only used when a Capistrano deployment or rollback fails
after 'deploy:failed', 'delayed_job:restart'
