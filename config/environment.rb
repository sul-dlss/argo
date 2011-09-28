# Load the rails application
require File.expand_path('../application', __FILE__)

Dor::Config.declare(:argo) do
  stacks do
    url nil
  end
end

# Initialize the rails application
RubyDorServices::Application.initialize!
