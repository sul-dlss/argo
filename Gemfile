source "https://rubygems.org"

gem 'addressable', '=2.3.5' #>=2.3.6 breaks things w/ the following error on rails startup:  "can't modify frozen Addressable::URI"
gem 'barby'
gem 'coderay'
gem 'confstruct', "~> 0.2.4"
gem 'dalli'
gem 'haml'
gem 'kaminari'
gem 'kgio'  
gem 'mysql2'
gem 'net-sftp'
gem 'nokogiri', '=1.6.5' #TODO: this should go, i just needed to get rid of nokogiri upgrade errors to do other stuff first
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'progressbar'
gem 'rack-webauth', :git => "https://github.com/nilclass/rack-webauth.git"
gem 'rake'
gem 'rest-client'
gem 'retries'
gem 'ruby-graphviz'
gem 'squash_rails', :require => 'squash/rails'
gem 'squash_ruby',  :require => 'squash/ruby'
gem 'thin' # or mongrel
gem 'thread', :git => 'https://github.com/meh/ruby-thread.git'
gem 'unicode'

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora'
gem 'blacklight', '~> 5.9.0' #TODO: unpin BL, stop pointing BLH to github
gem 'blacklight-hierarchy', :git => 'https://github.com/sul-dlss/blacklight-hierarchy.git', :branch => 'develop'
gem 'blacklight-marc'
gem 'dor-services', '~> 5', :git => 'https://github.com/sul-dlss/dor-services.git', :branch => 'develop'
gem 'dor-workflow-service'
gem 'druid-tools', '~> 0.3.0' #TODO: does argo use this directly?  can i get rid of this?
gem 'is_it_working-cbeer'
gem 'jettywrapper'
gem 'moab-versioning'
gem 'mods_display'
gem 'osullivan', '~> 0.0.3' #TODO: might want to remove this entirely since argo doesn't use it directly
gem 'rails', '~> 4'
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'rsolr-client-cert', '~> 0.5.2'
gem 'solrizer'
gem 'stanford-mods'

group :test, :development do
  gem 'http_logger'
  gem 'selenium-webdriver'
  gem 'unicorn'
  gem 'rspec-rails', '~> 3'
  gem 'capybara'
  gem "rack-test", :require => "rack/test"
  gem 'simplecov', :require => false
  gem 'pry-debugger', :platform => :ruby_19  # debugger can't handle ruby 2.x
  gem 'pry-byebug',   :platform =>[:ruby_20, :ruby_21]
  gem 'pry-remote'
  gem 'pry-rails'
end

group :development do
  gem 'ruby-prof'
  gem 'sqlite3'
end

group :assets do
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
  # gem 'jquery-rails', '=2.1.4'  # jquery-rails vers 2.1.4 uses jquery vers 1.8.3
  gem 'jquery-rails'
  gem 'jquery-validation-rails'
  gem 'therubyracer', "~> 0.11"
  gem 'sass-rails'
  gem 'bootstrap-sass'
end

group :deployment do
  gem 'capistrano', '=3.2.1'
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel', '3.1.0'
end
