# Load the rails application
require File.expand_path('../application', __FILE__)

require File.join(Rails.root, 'config', 'environments', "dor_#{Rails.env}")
# Initialize the rails application
Argo::Application.initialize!
