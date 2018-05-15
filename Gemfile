
source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
 # Call 'byebug' anywhere in the code to stop execution and get a debugger console
 gem 'byebug', platform: :mri
end

group :development do
 # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
 gem 'listen', '>= 3.0.5', '< 3.2'
 gem 'web-console'
 # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
 gem 'spring'
 gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'barby'
gem 'bootstrap-sass'
gem 'cancancan'
gem 'coderay'
gem 'config'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'ebnf', '1.0.0' # 1.0 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'equivalent-xml', '>= 0.6.0' # For ignoring_attr_values() with arguments
gem 'erubis' # implicit dependency required by rdf-rdfa/haml, no longer provided by default in Rails 5.1
gem 'eye' # NOTE: if eye is upgraded, see the note in the 'bin/eye' script about checking to see whether that script needs upgrading (which won't happen automatically).
gem 'faraday'
gem 'honeybadger', '~> 3.0'
gem 'jqgrid-jquery-rails'
gem 'jquery-ui-rails', '~> 5.0'
gem 'jquery-validation-rails'
gem 'linkeddata', '~> 1.99' # pinned for faster dependency resolution
gem 'mysql2', '~> 0.4.5'
gem 'net-sftp'
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.6'
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'rack-webauth', git: 'https://github.com/nilclass/rack-webauth.git'
gem 'rake'
gem 'rdf', '~> 1.99' # pinned for faster dependency resolution
gem 'rdf-microdata', '2.0.2' # 2.0.3 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'rdf-reasoner', '~> 0.3.0' # 0.4 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'rdf-tabular', '~> 0.3.0' # 0.4 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'retries'
gem 'ruby-graphviz'
gem 'ruby-prof'
gem 'rubyzip'
gem 'whenever', require: false

# Stanford/Hydra related gems
gem 'active-fedora', '~> 8.2'
gem 'blacklight', '~> 6.0'
gem 'blacklight-hierarchy'
gem 'dor-services', '>= 5.22.2', '< 6'
gem 'moab-versioning'
gem 'mods_display'
gem 'okcomputer' # monitors application and its dependencies
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'stanford-mods'
gem 'sul_styles', '~> 0.3'

group :test, :development do
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'http_logger', require: false # Change this to `true` to see all http requests logged
  gem 'jettywrapper'
  gem 'pry-remote' # allows you to attach remote session to pry
  gem 'rails-controller-testing'
  gem 'rspec-rails', '~> 3.5'
  gem 'rubocop', require: false
  gem 'sqlite3'
end

group :development do
  gem 'rack-mini-profiler', require: false # used for performance profiling
end

group :test do
  gem 'capybara'
  gem 'chromedriver-helper' # installs the chromedriver for selenium tests
  gem 'codeclimate-test-reporter', require: false
  gem 'coveralls', require: false
  gem 'selenium-webdriver' # for js testing
  gem 'simplecov', require: false
  gem 'webmock', require: false
end

group :deployment do
  gem 'capistrano', '~> 3.6'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-shared_configs'
  gem 'capistrano3-delayed-job', '~> 1.0'
  gem 'dlss-capistrano', '~> 3.1'
end
