# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'barby' # Barby creates barcodes. Used in generating tracksheets
gem 'bootsnap', '>= 1.4.2', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'cancancan' # authorization
gem 'coderay' # Pretty format for XML
gem 'config'
gem 'cssbundling-rails', '~> 1.1'
gem 'devise'
gem 'devise-remote-user', '~> 1.0'
gem 'dry-monads'
gem 'equivalent-xml', '>= 0.6.0' # For ignoring_attr_values() with arguments
gem 'faraday' # HTTP client library
gem 'faraday-multipart'
gem 'honeybadger'
gem 'jbuilder', '~> 2.5' # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jsbundling-rails', '~> 1.0'
gem 'lograge'
gem 'nokogiri', '~> 1.14'
gem 'okcomputer' # monitors application and its dependencies
gem 'prawn', '~> 1' # Prawn is used to create "tracksheets"
gem 'prawn-table'
gem 'propshaft'
gem 'puma', '~> 5.6' # Use Puma as the app server
gem 'rails', '~> 7.0.2'
gem 'rake'
gem 'reform-rails'
gem 'retries'
gem 'roo', '~> 2.9.0' # work with newer Excel files and other types (xlsx, ods, csv)
gem 'roo-xls' # needed to work with legacy Excel files (xls)
gem 'rubyzip'
gem 'sidekiq', '~> 7.1'
gem 'turbo-rails', '~> 1.0'
gem 'view_component'
gem 'zip_tricks'

# Stanford related gems
gem 'blacklight', '~> 7.25', '< 7.34' # Avoid 7.34 until we have time to troubleshoot test failures
gem 'blacklight-hierarchy', '~> 6.1'
gem 'dor-services-client', '~> 14.7'
gem 'dor-workflow-client', '~> 7.0'
gem 'druid-tools'
gem 'folio_client', '~> 0.13'
gem 'mods_display', '~> 1.0'
gem 'preservation-client', '~> 6.2'
gem 'rsolr'
gem 'sdr-client', '~> 2.0'

group :test, :development do
  gem 'debug'
  gem 'erb_lint', '~> 0.4.0', require: false
  gem 'factory_bot_rails'
  gem 'http_logger', require: false # Change this to `true` to see all http requests logged
  gem 'pry-remote' # allows you to attach remote session to pry
  gem 'rspec-rails', '~> 5.0'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'sqlite3', '~> 1.4'
end

group :development do
  gem 'listen', '~> 3.2' # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'cocina-models', '~> 0.69' # only need RSpec matchers here; don't need to pin to patch level
  gem 'rspec_junit_formatter' # needed for test coverage in CircleCI
  gem 'selenium-webdriver' # for js testing
  gem 'simplecov'
  gem 'webmock', require: false
  gem 'write_xlsx' # this is required to write an xlsx file prior to opening it with roo in tests
end

group :deployment do
  gem 'capistrano-maintenance', '~> 1.2', require: false
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'dlss-capistrano', require: false
end

group :production do
  gem 'mysql2', '~> 0.5'
end
