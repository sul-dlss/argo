source "https://rubygems.org"

gem 'addressable', '=2.3.5' #>=2.3.6 breaks things w/ the following error on rails startup:  "can't modify frozen Addressable::URI"
gem 'barby'
gem 'coderay'
gem 'confstruct', "~> 0.2.4"
gem 'dalli'
gem 'equivalent-xml', '~> 0.5.1'
gem 'haml'
gem 'kaminari'
gem 'kgio'
gem 'mysql2'
gem 'net-sftp'
gem 'nokogiri', '~> 1.6'
gem 'prawn', '~> 1'
gem 'prawn-table'
gem 'progressbar'
gem 'rack-webauth', :git => "https://github.com/nilclass/rack-webauth.git"
gem 'rake'
gem 'rest-client'
gem 'retries'
gem 'ruby-graphviz'
gem 'squash_rails', '=1.3.3', :require => 'squash/rails'  #TODO: upgrading to 1.3.4 results in weird error output at end of deployment, pinning for now
gem 'squash_ruby',  :require => 'squash/ruby'
gem 'thin' # or mongrel
gem 'thread', :git => 'https://github.com/meh/ruby-thread.git'
gem 'unicode'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'daemons'

# Stanford/Hydra related gems
gem 'about_page'
gem 'active-fedora'
gem 'blacklight', '~> 5.9.0' #TODO: BL >= 5.10.x has new deprecation warnings vs <= 5.9.x, will investigate and unpin after current upgrade stuff has settled
gem 'blacklight-hierarchy'
gem 'blacklight-marc'
gem 'dor-services', '~> 5.0', :git => 'https://github.com/sul-dlss/dor-services.git', :branch => 'solrization_fixes3'
gem 'dor-workflow-service', '~> 1.7'
gem 'is_it_working-cbeer'
gem 'jettywrapper'
gem 'moab-versioning'
gem 'mods_display'
gem 'rails', '~> 4.0' # specifying because we expect a major vers upgrade to break things
gem 'responders', '~> 2.0'
gem 'rsolr'
gem 'rsolr-client-cert', '~> 0.5.2'
gem 'solrizer'
gem 'sprockets', '~> 2.12' # upgrading to 3.x introduces a deployment error, where cap tries to backup a non-existent manifest-*.js file
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
  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'jquery-validation-rails'
  gem 'jqgrid-jquery-rails'
  gem 'therubyracer', "~> 0.11"
  gem 'sass-rails'
  gem 'bootstrap-sass'
end

group :deployment do
  gem 'capistrano', '=3.2.1' # pinned because inadvertent capistrano upgrades tend to cause deployment issues.
  gem 'capistrano-rails'
  gem 'lyberteam-capistrano-devel', '3.1.0'
  gem 'capistrano3-delayed-job', '~> 1.0'
end
