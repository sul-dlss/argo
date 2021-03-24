# frozen_string_literal: true

# rubocop:disable Rails/RakeEnvironment
desc 'Install Javascript dependencies via `yarn`'
task :yarn_install do
  on roles(:web) do
    within release_path do
      execute("cd #{release_path} && yarn install")
    end
  end
end
# rubocop:enable Rails/RakeEnvironment

before 'deploy:assets:precompile', 'yarn_install'
