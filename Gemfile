source :rubygems
source "http://sulair-rails-dev.stanford.edu"

# Uncomment the following line to use the head revision of the DLSS active_fedora fork.
# WARNING: Only use when there are pending pull requests that haven't been merged upstream yet.
# Comment it back out when all pull requests are merged.
if File.exists?(fn=File.join(ENV['HOME'],".static-gems/dor-services")) &! ENV['CLEAN_BUNDLE']
  gem 'dor-services', :path => fn
else
  gem 'dor-services', "~> 3.1.0"
end
if File.exists?(fn=File.join(ENV['HOME'],".static-gems/active_fedora")) &! ENV['CLEAN_BUNDLE']
  gem 'active-fedora', :path => fn
else
  gem 'active-fedora', "~> 4.0.0.rc9"
end

gem 'rails', '3.2.0'
gem "blacklight", '~>3.2.0'

gem 'rake'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
gem "solrizer-fedora"
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

group :development do
  gem 'pry'
  gem 'pry-remote'
  gem 'ruby-prof'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'lyberteam-devel', '~> 0.5.1'
  gem 'net-ssh-kerberos'
end