source 'https://rubygems.org'

gem 'barby'
gem 'bootstrap-sass'
gem 'cancancan'
gem 'coderay'
gem 'coffee-rails'
gem 'config'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'equivalent-xml', '>= 0.6.0'   # For ignoring_attr_values() with arguments
gem 'faraday'
gem 'eye'  # NOTE: if eye is upgraded, see the note in the 'bin/eye' script about checking to see whether that script needs upgrading (which won't happen automatically).
gem 'honeybadger', '~> 2.0'
gem 'jbuilder', '~> 2.0'
gem 'jqgrid-jquery-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-validation-rails'
gem 'linkeddata', '~> 1.99' # pinned for faster dependency resolution
gem 'mysql2', '~> 0.3.2'    # Temporary fix for mysql2/rails incompatibility, see https://github.com/brianmario/mysql2/issues/675
gem 'net-sftp'
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.6'
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'rack-webauth', git: 'https://github.com/nilclass/rack-webauth.git'
gem 'rails', '4.2.7.1'
gem 'activemodel', '4.2.7.1'
gem 'rake'
gem 'rdf', '~> 1.99' # pinned for faster dependency resolution
gem 'ebnf', '1.0.0' # 1.0 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'rdf-reasoner', '~> 0.3.0' # 0.4 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'rdf-tabular', '~> 0.3.0' # 0.4 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'rdf-microdata', '2.0.2' # 2.0.3 requires rdf 2.x; bundler bug stops it from resolving correctly
gem 'retries'
gem 'ruby-graphviz'
gem 'ruby-prof'
gem 'sass-rails'
gem 'sprockets', '~> 3.4'
gem 'therubyracer', '~> 0.11'
gem 'uglifier', '>= 1.0.3'
gem 'whenever', require: false

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora', '~> 8.2'
gem 'blacklight', '~> 6.0'
gem 'blacklight-hierarchy'
gem 'dor-services', '>= 5.14.0', '< 6'
gem 'is_it_working-cbeer'
gem 'moab-versioning'
gem 'mods_display'
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'stanford-mods'
gem 'sul_styles', '~> 0.3'

# useful for debugging, even in prod
gem 'pry-byebug' # Adds step-by-step debugging and stack navigation capabilities to pry using byebug
gem 'pry-rails' # use pry as the rails console shell instead of IRB

group :test, :development do
  gem 'capybara' # used by wfs_rails in development
  gem 'capybara_discoball' # use external server just for capybara; relied on by 'wfs_rails'
  gem 'jettywrapper'
  gem 'http_logger'
  gem 'rspec-rails', '~> 3.5'
  gem 'pry-doc'
  gem 'pry-remote'  # allows you to attach remote session to pry
  gem 'wfs_rails', '~> 0.0.2'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'rubocop', require: false
  gem 'sqlite3'
end

group :development do
  gem 'rack-mini-profiler', require: false # used for performance profiling
end

group :test do
  gem 'poltergeist' # for js testing
  gem 'webmock', require: false
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem 'codeclimate-test-reporter', require: false
end

group :deployment do
  gem 'capistrano', '= 3.6.0' # pinned because inadvertent capistrano upgrades tend to cause deployment issues.
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano', '~> 3.1'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
