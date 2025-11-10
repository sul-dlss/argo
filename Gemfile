# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'barby' # Barby creates barcodes. Used in generating tracksheets
gem 'bootsnap', '>= 1.4.2', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'cancancan' # authorization
gem 'coderay' # Pretty format for XML
gem 'config'
gem 'cssbundling-rails', '~> 1.1'
gem 'csv'
gem 'datacite'
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
gem 'nokogiri', '~> 1.18'
gem 'okcomputer' # monitors application and its dependencies
gem 'pg'
gem 'prawn', '~> 1' # Prawn is used to create "tracksheets"
gem 'prawn-table'
gem 'propshaft'
gem 'puma' # Use Puma as the app server
gem 'rails', '~> 8.0.0'
gem 'rake'
gem 'reform-rails'
gem 'retries'
gem 'roo', '~> 2.9.0' # work with newer Excel files and other types (xlsx, ods, csv)
gem 'roo-xls' # needed to work with legacy Excel files (xls)
gem 'rubyzip'
gem 'sidekiq', '~> 7.1'
gem 'turbo-rails', '~> 2.0'
gem 'view_component'
gem 'zip_tricks'

# Stanford related gems
gem 'blacklight', '~> 7.41'
# pinned because 6.7.0 is effectively coupled to BL >= 8.3.0 and Argo hasn't been updated to BL8 yet
gem 'blacklight-hierarchy', '~> 6.6.0'
gem 'dor-services-client', '~> 15.1'
gem 'druid-tools'
gem 'folio_client', '~> 0.13'
gem 'mods_display', '~> 1.0'
gem 'preservation-client', '~> 7.0'
gem 'purl_fetcher-client', '~> 1.3'
gem 'rsolr'
gem 'sdr-client', '~> 2.0'

group :test, :development do
  gem 'debug'
  gem 'erb_lint', require: false
  gem 'factory_bot_rails'
  gem 'http_logger', require: false # Change this to `true` to see all http requests logged
  gem 'rspec-rails', '~> 6.1'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
end

group :development do
  gem 'listen', '~> 3.2' # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'overmind'
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'cocina-models', '~> 0.69' # only need RSpec matchers here; don't need to pin to patch level
  gem 'rspec_junit_formatter' # used by CircleCI to format test results
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
