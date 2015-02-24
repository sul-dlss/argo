# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'argo'
set :repo_url, 'https://github.com/sul-dlss/argo.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

#TODO:  ask for user, should know what the name of the app is, should be able to build deploy_to from those
#TODO:  prompt for server name and use that to build hostname (based on app name)
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
set :linked_files, %w{config/database.yml config/solr.yml config/default_htaccess_directives}

# Default value for linked_dirs is []
set :linked_dirs, %w{log config/certs config/environments tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

before 'deploy:publishing', 'squash:write_revision'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

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

end
