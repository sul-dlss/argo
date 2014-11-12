source "https://rubygems.org"

gem 'stanford-mods'
gem 'mods_display'
gem 'dor-services', ">= 4.15.0"
gem 'dor-workflow-service', '~> 1.5'
gem "druid-tools", "~> 0.3.0"
gem "moab-versioning", "=1.3.3"
gem 'rails', '3.2.20'
gem "blacklight", '~>3.7'
gem 'blacklight-hierarchy', "~> 0.0.3"
gem 'net-sftp'
gem 'rake'
gem 'about_page'
gem 'is_it_working-cbeer'
gem 'rack-webauth', :git => "https://github.com/nilclass/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
gem "solrizer-fedora"
gem 'active-fedora'
gem "rsolr", :git => "https://github.com/sul-dlss/rsolr.git", :branch => "nokogiri"
gem "rsolr-client-cert", "~> 0.5.2"
gem 'confstruct', "~> 0.2.4"
gem "mysql2", "= 0.3.13"
gem "progressbar"
gem "haml"
gem "coderay"
gem "dalli"
gem "kgio"  
gem 'rest-client'
gem 'jettywrapper'
gem 'kaminari'
gem 'thread', :git => 'https://github.com/meh/ruby-thread.git'
gem 'addressable', '=2.3.5' #>=2.3.6 breaks things w/ the following error on rails startup:  "can't modify frozen Addressable::URI"
gem 'squash_ruby',  :require => 'squash/ruby'
gem 'squash_rails', :require => 'squash/rails'

group :test, :development do
  gem 'http_logger'
  gem 'selenium-webdriver'
  gem 'unicorn'
  gem 'rspec-rails', '~> 3'
  gem 'capybara'
  gem "rack-test", :require => "rack/test"
  gem 'simplecov', :require => false
  gem 'pry'
  gem 'pry-debugger'
  gem 'pry-remote'
  gem 'pry-rails'
end

group :development do
  gem 'ruby-prof'
  gem 'sqlite3'
end

group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'jquery-rails', '=2.1.4'  # jquery-rails vers 2.1.4 uses jquery vers 1.8.3
  gem 'jquery-validation-rails'
  gem 'therubyracer', "~> 0.11"
  gem 'sass-rails', '~> 3.2.0'
  gem 'compass-rails', '~> 1.0.0'
  gem 'compass-susy-plugin', '~> 0.9.0'
end

group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel', '=3.1.0.pre1'
end
