require 'wf_viz'

class Workflow
  attr_reader :name, :config
  
  def self.find(name)
    config_file = File.join(Rails.root,'config/workflows',name)+'.yaml'
    if File.exists?(config_file)
      config = File.exists?(config_file) ? YAML.load(File.read(config_file)) : {}
      self.new(name, config)
    else
      nil
    end
  end
  
  def self.[](name)
    self.find(name)
  end
  
  def initialize(name, config)
    @name = name
    @config = config
  end

  def graph
    @graph ||= WorkflowViz.from_config(self.name,config)
  end
  
  def processes
    @processes ||= (config.keys - ['repository']).sort do |a,b|
      if graph.processes[a].all_dependents.include?(b)
        -1
      elsif graph.processes[b].all_dependents.include?(a)
        +1
      else
        a <=> b
      end
    end
  end
  
end
