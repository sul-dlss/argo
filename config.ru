require 'config/setup_load_paths'
require 'lib/service'

set :environment, ENV['RACK_ENV'].to_sym
run DorServicesApp