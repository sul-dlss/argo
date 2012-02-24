source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'rails', '3.2.0'
gem "blacklight", '~>3.2.0'

gem 'rake'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
if File.exists?(fn=File.expand_path('../.dor-services',__FILE__))
  instance_eval File.read(fn)
else
  gem 'dor-services', "~> 3.0.2"
end
gem "solrizer-fedora"
gem "mysql2", "~> 0.3.0"
gem "progressbar"
gem "haml"
gem "coderay"

gem 'sass-rails',   '~> 3.2.3'
gem 'coffee-rails', '~> 3.2.1'
gem 'uglifier', '>= 1.0.3'
gem 'jquery-rails'

group :development do
  gem 'ruby-prof'
end

group :local do
  gem 'capistrano'
  gem 'lyberteam-devel', :path => '/Users/mbklein/workspace/gems/lyberteam-devel'
  gem 'net-ssh-kerberos'
end