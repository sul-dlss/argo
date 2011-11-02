# Load the rails application
require File.expand_path('../application', __FILE__)

module Argo
  Config = ModCons::Configuration.new(:'Argo::Config')

  Config.declare do
    urls do
      mdtoolkit nil
      purl nil
      stacks nil
    end
  end
  
  def self.configure *args, &block
    Argo::Config.configure *args, &block
  end
end

# Initialize the rails application
RubyDorServices::Application.initialize!
