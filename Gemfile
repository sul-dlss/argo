source 'https://rubygems.org'

gem 'barby'
gem 'bootstrap-sass'
gem 'coderay'
gem 'coffee-rails'
gem 'config'
gem 'daemons'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'equivalent-xml', '>= 0.6.0'   # For ignoring_attr_values() with arguments
gem 'jqgrid-jquery-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-validation-rails'
gem 'kaminari'
gem 'kgio'
gem 'mysql2', '~> 0.3.2'    # Temporary fix for mysql2/rails incompatibility, see https://github.com/brianmario/mysql2/issues/675
gem 'net-sftp'
gem 'newrelic_rpm'
gem 'nokogiri', '~> 1.6'
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'progressbar'
gem 'rack-webauth', :git => 'https://github.com/nilclass/rack-webauth.git'
gem 'rake'
gem 'rest-client'
gem 'retries'
gem 'ruby-graphviz'
gem 'sass-rails'
gem 'squash_rails', '=1.3.3', :require => 'squash/rails'  # TODO: upgrading to 1.3.4 results in weird error output at end of deployment, pinning for now
gem 'squash_ruby',  :require => 'squash/ruby'
gem 'therubyracer', '~> 0.11'
gem 'uglifier', '>= 1.0.3'
gem 'unicode'

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora'
gem 'blacklight', '~> 5.9.0' # TODO: BL >= 5.10.x has new deprecation warnings vs <= 5.9.x, will investigate and unpin after current upgrade stuff has settled
gem 'blacklight-hierarchy'
gem 'blacklight-marc'
gem 'dor-services', '~> 5.0', :git => 'https://github.com/sul-dlss/dor-services.git', :branch => 'develop'
gem 'is_it_working-cbeer'
gem 'jettywrapper'
gem 'moab-versioning'
gem 'mods_display'
gem 'rails', '~> 4.0' # specifying because we expect a major vers upgrade to break things
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'rsolr-client-cert', '~> 0.5.2'
gem 'ruby-prof'
gem 'solrizer'
gem 'sprockets', '~> 3.4'
gem 'stanford-mods'
gem 'sul_styles', '~> 0.3.0' # later versions require ruby 2.1 or higher

group :test, :development do
  gem 'http_logger'
  gem 'selenium-webdriver'
  gem 'unicorn'
  gem 'rspec-rails', '~> 3'
  gem 'capybara'
  gem 'rack-test', :require => 'rack/test'
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
end

group :development do
  gem 'rubocop', require: false
  gem 'sqlite3'
end

group :deployment do
  gem 'capistrano', '=3.2.1' # pinned because inadvertent capistrano upgrades tend to cause deployment issues.
  gem 'capistrano-rails', '=1.1.5' # pinned because otherwise deployment fails with:  NoMethodError: undefined method `verbosity' for "/usr/bin/env deploy:migrating\n":String
  gem 'capistrano-passenger'
  gem 'dlss-capistrano', '~> 3.1'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
