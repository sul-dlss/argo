source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'rake'
gem 'rack-flash'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem 'ruby-graphviz'
gem "mod-cons", ">=0.2.0"
if File.exists?(fn=File.expand_path('../.dor-services',__FILE__))
  instance_eval File.read(fn)
else
  gem 'dor-services', ">= 2.5.2"
end
gem "mysql2", "~> 0.2.7"
gem "progressbar"
gem "sqlite3-ruby", "~> 1.2.5"
gem "haml"
gem "sass"
gem "hassle", :git => "git://github.com/Papipo/hassle.git"
gem "blacklight", :git => "git://github.com/projectblacklight/blacklight.git", :branch => "feature-facet-refactoring"

gem 'rails', '3.0.8'
