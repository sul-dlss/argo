source "https://rubygems.org"

gem 'stanford-mods'
gem 'mods_display'
# gem 'dor-services', ">= 4.15.2"
gem 'dor-services', :git => "https://github.com/sul-dlss/dor-services.git", :branch => "rails4"
gem 'dor-workflow-service'
gem "druid-tools", "~> 0.3.0"
gem "moab-versioning"
gem 'rails', '3.2.21'
# gem 'rails', '~> 4'
# gem 'rails'
# gem "blacklight", '~> 3'
# gem "blacklight", '~> 4'
gem "blacklight"
# gem 'blacklight-hierarchy', "~> 0.0.3"
# gem 'blacklight-hierarchy', "~> 0.1.0"
gem 'osullivan', :git => "git://github.com/sul-dlss/osullivan.git", :branch => "development"  #TODO: this shouldn't remain in the final version since it's not a direct dependency of argo
gem 'net-sftp'
gem 'rake'
gem 'about_page'
gem 'is_it_working-cbeer'
gem 'rack-webauth', :git => "https://github.com/nilclass/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn'
gem 'prawn-table'
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
gem 'unicode'

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
  # gem 'coffee-rails', '~> 3.2.1'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
  # gem 'jquery-rails', '=2.1.4'  # jquery-rails vers 2.1.4 uses jquery vers 1.8.3
  gem 'jquery-rails'
  gem 'jquery-validation-rails'
  gem 'therubyracer', "~> 0.11"
  # gem 'sass-rails', '~> 3.2.0'
  gem 'sass-rails'
  # gem 'compass-rails', '~> 1.0.0'
  # gem 'compass-susy-plugin', '~> 0.9.0'
  gem 'bootstrap-sass'
end

group :deployment do
  gem 'capistrano', '=3.2.1'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel', '=3.1.0.pre1'
end
