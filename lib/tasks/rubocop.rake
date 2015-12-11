require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.options = %w(--format simple)
end
