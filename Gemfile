source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'dor-services', ">= 3.5.1"
gem 'rails', '3.2.0'
gem "blacklight", '~>3.2.0'
gem 'blacklight-hierarchy', :git => "git://github.com/sul-dlss/blacklight-hierarchy.git"

gem 'rake'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
gem "solrizer-fedora"
gem "rsolr", :git => "git://github.com/sul-dlss/rsolr.git", :branch => "nokogiri"
gem "rsolr-client-cert"
gem "mysql2", "~> 0.3.0"
gem "progressbar"
gem "haml"
gem "coderay"
gem "dalli"
gem "kgio"

gem 'sass-rails',   '~> 3.2.3'
gem 'coffee-rails', '~> 3.2.1'
gem 'uglifier', '>= 1.0.3'
gem 'jquery-rails'
gem 'therubyracer'

group :test, :development do
  gem 'unicorn'
  gem 'rspec-rails'
  gem "rack-test", :require => "rack/test"
end

group :development do
  gem 'pry'
  gem 'ruby-prof'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'rvm-capistrano'
  gem 'lyberteam-devel', '>=0.7.0'
  gem 'net-ssh-kerberos'
end