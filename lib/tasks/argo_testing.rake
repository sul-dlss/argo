# frozen_string_literal: true

begin
  require "standard/rake"
rescue
  LoadError
end

begin
  require "rspec/core/rake_task"
rescue LoadError
  desc "Run RSpec"
  task :spec do
    abort "Please install the rspec-rails gem to run rspec."
  end
end

task(:default).clear

desc "run linter and tests (for CI)"
task default: ["standard", "spec"]
