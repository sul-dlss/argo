source :rubygems
source "http://sulair-rails-dev.stanford.edu"

gem 'rake'
gem 'rack-flash'
gem 'rack-webauth', :git => "git://github.com/sul-dlss/rack-webauth.git"
gem 'thin' # or mongrel
gem 'prawn', :git => "git://github.com/mbklein/prawn.git"
gem 'barby'
gem "dor-services", ">=1.3.0"
#gem "dor-services", :path => "/Users/mbklein/Workspace/gems/dor-services/"
gem "mod-cons", ">=0.2.0"
gem "mysql2", "~> 0.2.7"
gem "sqlite3-ruby", "~> 1.2.5"
gem "haml"
gem "sass"

gem 'rails', '3.0.8'

group :development do
  if File.exists?(mygems = File.join(ENV['HOME'],'.gemfile'))
    instance_eval(File.read(mygems))
  end
  gem "lyberteam-devel"
end

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
