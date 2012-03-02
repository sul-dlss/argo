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
  
  Config = Confstruct::Configuration.new do
    reindex_on_the_fly false
    urls do
      mdtoolkit nil
      purl nil
      stacks nil
    end
  end
end

require File.join(Rails.root, 'config', 'environments', "dor_#{Rails.env}")
# Initialize the rails application
Argo::Application.initialize!
