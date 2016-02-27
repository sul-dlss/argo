source 'https://rubygems.org'

gem 'barby'
gem 'bootstrap-sass'
gem 'coderay'
gem 'coffee-rails'
gem 'config'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'equivalent-xml', '>= 0.6.0'   # For ignoring_attr_values() with arguments
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
gem 'rack-webauth', :git => 'https://github.com/nilclass/rack-webauth.git'
gem 'rails', '~> 4.0' # specifying because we expect a major vers upgrade to break things
gem 'rake'
gem 'rest-client'
gem 'retries'
gem 'ruby-graphviz'
gem 'ruby-prof'
gem 'sass-rails'
gem 'sprockets', '~> 3.4'
gem 'squash_rails', '=1.3.3', :require => 'squash/rails'  # TODO: upgrading to 1.3.4 results in weird error output at end of deployment, pinning for now
gem 'squash_ruby',  :require => 'squash/ruby'
gem 'therubyracer', '~> 0.11'
gem 'uglifier', '>= 1.0.3'

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora'
gem 'blacklight', '~> 5.11.3' # More deprecation warnings from 5.11.3 to 5.16
gem 'blacklight-hierarchy'
gem 'dor-services', '~> 5.4', '>= 5.4.2'
gem 'is_it_working-cbeer'
gem 'jettywrapper'
gem 'moab-versioning'
gem 'mods_display'
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'stanford-mods'
gem 'sul_styles', '~> 0.3'

group :test, :development do
  gem 'http_logger'
  gem 'rspec-rails', '~> 3'
  gem 'capybara'
  gem 'simplecov', :require => false
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-remote'
  gem 'pry-rails'
  gem 'coveralls', require: false
  gem 'poltergeist'
  gem 'capybara_discoball'
  gem 'wfs_rails', '~> 0.0.2'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'webmock', require: false
end

group :development do
  gem 'rubocop', require: false
  gem 'sqlite3'
end

group :deployment do
  gem 'capistrano', '= 3.4.0' # pinned because inadvertent capistrano upgrades tend to cause deployment issues.
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano', '~> 3.1'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
