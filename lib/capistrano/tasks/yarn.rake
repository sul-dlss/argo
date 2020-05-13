# frozen_string_literal: true

desc 'Install Javascript dependencies via `yarn`'
task :yarn_install do
  on roles(:web) do
    within release_path do
      execute("cd #{release_path} && yarn install")
    end
  end
end

before 'deploy:assets:precompile', 'yarn_install'
