# frozen_string_literal: true

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run rubocop'
  task rubocop: :environment do
    abort 'Please install the rubocop gem to run rubocop.'
  end
end

begin
  require 'rspec/core/rake_task'
rescue LoadError
  desc 'Run RSpec'
  task spec: :environment do
    abort 'Please install the rspec-rails gem to run rspec.'
  end
end

desc 'Run erb_lint against ERB files'
task erblint: :environment do
  puts 'Running erblint...'
  system('bundle exec erb_lint --lint-all --format compact')
end

desc 'Run Yarn linter against JS files'
task jslint: :environment do
  puts 'Running JS linters...'
  system('yarn run lint')
end

desc 'Run all configured linters'
task lint: %i[rubocop erblint jslint]

task(:default).clear

desc 'run bundle audit'
task bundle_audit: :environment do
  puts 'Running bundle audit...'
  system('bin/bundler-audit')
end

desc 'run security audit'
task security_audit: :environment do
  puts 'Running security audit...'
  system('bin/brakeman -i config/brakeman.ignore')
end

desc 'run bundle outdated'
task bundle_outdated: :environment do
  puts 'Running bundle outdated...'
  system('bin/bundle outdated')
end

desc 'run yarn outdated'
task yarn_outdated: :environment do
  puts 'Running yarn outdated...'
  system('yarn outdated')
end

desc 'run linters, audits and tests (for CI)'
task default: %i[lint bundle_audit security_audit bundle_outdated yarn_outdated spec]

desc 'Run all configured security and version audits'
task audit: %i[bundle_audit bundle_outdated yarn_outdated security_audit]
