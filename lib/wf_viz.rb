require 'graphviz'

class WorkflowViz
  
  FILL_COLORS = { 'waiting' => "#FFFFFF", 'error' => "#FF0000", 'completed' => "#00CF00", 'unknown' => "#CFCFCF" }
  TEXT_COLORS = { 'waiting' => "black", 'error' => "black", 'completed' => "black", 'unknown' => "black" }

  attr_reader :repo, :name, :processes, :graph, :root
  
  def self.from_config(name, config, parent = nil)
    wf = self.new(config['repository'], name, parent)
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
  
  def initialize(repo, name, parent = nil)
    @repo = repo
    @name = name
    if parent.nil?
      @graph = GraphViz.new(qname)
    else
      @graph = parent.add_graph(qname)
    end
    @root = self.add_node(name)
    @root.shape = 'circle'
    @processes = {}
  end
  
  def qname
    [@repo,@name].join(':')
  end
  
  def add_process(name, external = false)
    pqname = name.split(/:/).length == 3 ? name : [qname,name].join(':')
    p = Process.new(self, pqname, name)
    @processes[name] = p
    return p
  end
  
  def finish
    @processes.values.each do |process|
      process.node.fontname = 'Helvetica'
      if process.dependents.length == 0
        edge = (@root << process.node)
        edge.dir = 'both'
        edge.arrowhead = 'vee'
        edge.arrowtail = 'none'
      end
    end
    
    if @processes.values.select { |p| p.dependents.length == 0 }.all? { |p| p.status == 'completed' }
      @root.color = FILL_COLORS['completed']
      @root.fontcolor = TEXT_COLORS['completed']
    end
    @root.fontname = 'Helvetica'
  end
  
  def method_missing(sym,*args)
    if @graph.respond_to?(sym)
      @graph.send(sym,*args)
    else
      super
    end
  end
  
  class Process
    
    attr_reader :name, :status, :node, :dependents
    
    def initialize(graph, id, name)
      $stderr.puts id
      @name = name
      @graph = graph
      @node = @graph.add_node(id)
      @node.shape = 'box'
      @node.label = name
      @dependents = []
      self.set_status('unknown')
    end
    
    def id
      @node.id
    end
    
    def status=(s)
      @status = s
      if s == 'external'
        @node.fillcolor = "gray"
        @node.fontcolor = "black"
        @node.style = "dashed"
      else
        @node.fillcolor = FILL_COLORS[s] || "yellow"
        @node.fontcolor = TEXT_COLORS[s]
        @node.style = "filled"
      end
    end
    
    def set_status(s)
      self.status = s
      return self
    end
    
    def depends_on(*processes)
      wf1 = self.id.split(/:/)[0..1].join(':')
      processes.each { |process|
        wf2 = process.id.split(/:/)[0..1].join(':')
        edge = (@node << process.node)
        edge.dir = 'both'
        edge.arrowhead = 'vee'
        edge.arrowtail = 'none'
        if (wf1 != wf2)
          edge.style = 'dashed'
        end
        process.dependents << self
      }
      return self
    end
    
    def same_as(process)
      @node = process.node  
    end
    
    def all_dependents
      dependents.collect { |p| p.all_dependents + [p.name] }.flatten.uniq
    end
    
  end

end
