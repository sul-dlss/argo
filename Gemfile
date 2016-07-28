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
gem 'jqgrid-jquery-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-validation-rails'
gem 'mysql2', '~> 0.3.2'    # Temporary fix for mysql2/rails incompatibility, see https://github.com/brianmario/mysql2/issues/675
gem 'net-sftp'
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.6'
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'rack-webauth', git: 'https://github.com/nilclass/rack-webauth.git'
gem 'rails', '~> 4.0' # specifying because we expect a major vers upgrade to break things
gem 'rake'
gem 'retries'
gem 'ruby-graphviz'
gem 'ruby-prof'
gem 'sass-rails'
gem 'sprockets', '~> 3.4'
gem 'squash_rails', '=1.3.3', require: 'squash/rails'  # TODO: upgrading to 1.3.4 results in weird error output at end of deployment, pinning for now
gem 'squash_ruby', require: 'squash/ruby'
gem 'therubyracer', '~> 0.11'
gem 'uglifier', '>= 1.0.3'
gem 'whenever', require: false

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora'
gem 'blacklight', '~> 5.18'
gem 'blacklight-hierarchy'
gem 'dor-services', '~> 5.9', '>= 5.9.1'
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
  gem 'pry-doc'
  gem 'pry-remote'  # allows you to attach remote session to pry
  gem 'wfs_rails', '~> 0.0.2'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'rubocop', require: false
  gem 'sqlite3'
end

group :test do
  gem 'rspec-rails', '~> 3'
  gem 'poltergeist' # for js testing
  gem 'webmock', require: false
  gem 'simplecov', require: false
  gem 'coveralls', require: false
  gem "codeclimate-test-reporter", require: false
end

group :deployment do
  gem 'capistrano', '= 3.4.0' # pinned because inadvertent capistrano upgrades tend to cause deployment issues.
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano', '~> 3.1'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
