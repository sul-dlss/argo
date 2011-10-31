# Load the rails application
require File.expand_path('../application', __FILE__)

Dor::Config.declare(:argo) do
  mdtoolkit { url nil }
  purl      { url nil }
  stacks    { url nil }
end

# Initialize the rails application
RubyDorServices::Application.initialize!
