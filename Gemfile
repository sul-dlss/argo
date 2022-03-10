# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.4'
# Use Puma as the app server
gem 'puma', '~> 5.5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

gem 'cssbundling-rails', '~> 0.2.4'
gem 'jsbundling-rails', '~> 0.1.9'

gem 'view_component', '~> 2.49'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'listen', '~> 3.2'
  gem 'web-console'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Barby creates barcodes. Used in generating tracksheets
gem 'barby'
gem 'cancancan'
# Pretty format for XML
gem 'coderay'
gem 'config'
gem 'dry-monads'
gem 'equivalent-xml', '>= 0.6.0' # For ignoring_attr_values() with arguments
gem 'faraday'
gem 'faraday-multipart'
gem 'honeybadger', '~> 4.1'
gem 'lograge'
gem 'sidekiq', '~> 6.0'

gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.12'
# Prawn is used to create "tracksheets"
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'rake'
gem 'reform-rails'
gem 'retries'
gem 'ruby-prof'
gem 'rubyzip'
gem 'turbo-rails', '~> 1.0'
gem 'zip_tricks', '5.3.1' # 5.3.1 is required as 5.4+ breaks the download all feature

# openapi_parser is an indirect dependency that's being pinned for now, because 1.0 introduces
# stricter date-time format parsing, which breaks the test suite
# see https://app.circleci.com/pipelines/github/sul-dlss/argo/3007/workflows/17473c95-b882-4d9b-a167-7ac16849573b/jobs/6771
gem 'openapi_parser', '< 1.0'

# Stanford related gems
gem 'blacklight', '~> 7.20'
gem 'blacklight-hierarchy', '~> 6.0'
gem 'dor-services-client', '~> 8.0'
gem 'dor-workflow-client', '~> 4.0'
gem 'druid-tools'
gem 'mods_display', '~> 1.0.0.alpha1'
gem 'okcomputer' # monitors application and its dependencies
gem 'preservation-client', '~> 4.0'
gem 'rsolr'
gem 'sdr-client', '~> 0.60'

gem 'devise'
gem 'devise-remote-user', '~> 1.0'

# useful for debugging, even in prod
gem 'pry-byebug' # Adds step-by-step debugging and stack navigation capabilities to pry using byebug
gem 'pry-rails' # use pry as the rails console shell instead of IRB

group :test, :development do
  gem 'erb_lint', '~> 0.0.31', require: false
  gem 'factory_bot_rails'
  gem 'http_logger', require: false # Change this to `true` to see all http requests logged
  gem 'pry-remote' # allows you to attach remote session to pry
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 5.0'
  gem 'rubocop', '~> 1.24', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', '~> 2.1', require: false
  gem 'sqlite3', '~> 1.4.2'
end

group :development do
  gem 'rack-mini-profiler', require: false # used for performance profiling
end

group :test do
  gem 'capybara'
  gem 'rspec_junit_formatter' # needed for test coverage in CircleCI
  gem 'selenium-webdriver' # for js testing
  gem 'simplecov'
  gem 'webdrivers' # installs the chrome for selenium tests
  gem 'webmock', require: false
end

group :deployment do
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'dlss-capistrano', require: false
end

group :production do
  gem 'mysql2', '~> 0.5'
end
