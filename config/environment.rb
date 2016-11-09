# Load the Rails application.
require_relative 'application'

require File.join(Rails.root, 'config', 'environments', "dor_#{Rails.env}")
# Initialize the Rails application.
Rails.application.initialize!
