require 'graphviz'

class WorkflowViz < GraphViz

  attr_reader :name, :processes
  
  def self.from_config(name, config)
    wf = self.new(name)
    config.keys.each { |p| wf.add_process(p.to_s) unless p == 'repository' }
    config.keys.each { |p|
      if wf.processes[p]
        Array(config[p]['prerequisite']).each { |prereq|
          prereq.sub!(/^#{config['repository']}:#{name}:/e,'')
          if wf.processes[prereq]
            wf.processes[p].depends_on(wf.processes[prereq])
          else
            wf.processes[p].depends_on(wf.add_process(prereq).set_status('external'))
          end
        }
      end
    }
    wf.finish
    return wf
  end
  
  def initialize(name)
    super(name)
    @name = name
    @root = self.add_node(name)
    @processes = {}
  end
  
  def add_process(name, external = false)
    p = Process.new(self, name)
    @processes[name] = p
    return p
  end
  
  def finish
    @processes.values.each { |process|
      if process.dependents.length == 0
        edge = (@root << process.node)
        edge['dir'] = 'both'
        edge['arrowhead'] = 'none'
        edge['arrowtail'] = 'vee'
      end
    }
  end
  
  class Process
    
    STATUSES = { :waiting => "white", :error => "red", :completed => "green" }
    attr_reader :name, :status, :node, :dependents
    
    def initialize(graph, name)
      @name = name
      @graph = graph
      @node = @graph.add_node(name)
      @node.label = name
      @dependents = []
      self.set_status('waiting')
    end
    
    def id
      @node.id
    end
    
    def status=(s)
      if s.to_sym == :external
        @node["fillcolor"] = "white"
        @node["style"] = "dashed"
      else
        @node["fillcolor"] = STATUSES[s.to_sym] || "yellow"
        @node["style"] = "filled"
      end
    end
    
    def set_status(s)
      self.status = s
      return self
    end
    
    def depends_on(*processes)
      processes.each { |process|
        edge = (@node << process.node)
        edge['dir'] = 'both'
        edge['arrowhead'] = 'none'
        edge['arrowtail'] = 'vee'
        process.dependents << self
      }
      return self
    end

    def all_dependents
      dependents.collect { |p| p.all_dependents + [p.name] }.flatten.uniq
    end
    
  end

end
