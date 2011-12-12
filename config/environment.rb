# Load the rails application
require File.expand_path('../application', __FILE__)

module Argo
  class << self
    def version
      '1.5.4'
    end

    def configure *args, &block
      Argo::Config.configure *args, &block
    end
  end
  
  Config = ModCons::Configuration.new(:'Argo::Config')

  Config.declare do
    reindex_on_the_fly true
    urls do
      mdtoolkit nil
      purl nil
      stacks nil
    end
  end
end

# Initialize the rails application
RubyDorServices::Application.initialize!
