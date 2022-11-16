# frozen_string_literal: true

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  desc "Run rubocop"
  task rubocop: :environment do
    abort "Please install the rubocop gem to run rubocop."
  end
end

begin
  require "rspec/core/rake_task"
rescue LoadError
  desc "Run RSpec"
  task spec: :environment do
    abort "Please install the rspec-rails gem to run rspec."
  end
end

task(:default).clear

desc "run linter and tests (for CI)"
task default: ["rubocop", "spec"]
