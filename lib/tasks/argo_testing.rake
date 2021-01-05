# frozen_string_literal: true

require 'fileutils'
require 'retries'

task(:default).clear
desc 'run specs and rubocop (for CI)'
task default: %i[rubocop spec]

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run rubocop'
  task :rubocop do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

require 'rspec/core/rake_task' if %w[test development].include? Rails.env
