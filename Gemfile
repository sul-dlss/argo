source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'rake'
gem 'rack-flash'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', ">=0.12.0"
gem 'barby'
gem "mod-cons", ">=0.2.0"
gem "mysql2", "~> 0.2.7"
gem "sqlite3-ruby", "~> 1.2.5"
gem "haml"
gem "sass"
gem "hassle", :git => "git://github.com/Papipo/hassle.git"
gem "blacklight", :git => "git://github.com/projectblacklight/blacklight.git", :branch => "feature-facet-refactoring"

gem 'rails', '3.0.8'

dor_services_spec = ">= 1.7.2"
group :test do
  dor_services_spec = {:git => "/afs/ir/dev/dlss/git/lyberteam/dor-services-gem.git", :tag => 'test'}
end
group :development do
  dor_services_spec =
    File.directory?("/Users/mbklein/Workspace/gems/dor-services") ? 
      { :path => "/Users/mbklein/Workspace/gems/dor-services/" } : 
      { :git => "/afs/ir/dev/dlss/git/lyberteam/dor-services-gem.git", :tag => 'dev' }
end
gem "dor-services", dor_services_spec

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'
# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
