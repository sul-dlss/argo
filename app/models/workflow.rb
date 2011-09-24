require 'graphviz'

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
    @config.each_pair { |k,v|
      if v.is_a?(Hash)
        if v['prerequisite'].is_a?(String)
          v['prerequisite'] = v['prerequisite'].split(/\s*,\s*/)
        end
      end
    }
  end

  def graph(parent = nil)
    Graph.from_config(self.name,config,parent)
  end
  
  def processes
    @processes ||= (config.keys - ['repository']).sort do |a,b|
      if graph.processes[a].all_prerequisites.include?(b)
        +1
      elsif graph.processes[b].all_prerequisites.include?(a)
        -1
      else
        b <=> a
      end
    end
  end
  
end

class Workflow::Graph
  
  FILL_COLORS = { 'waiting' => "white", 'error' => "#8B0000", 'completed' => "darkgreen", 'unknown' => "#CFCFCF" }
  TEXT_COLORS = { 'waiting' => "black", 'error' => "white", 'completed' => "white", 'unknown' => "black" }

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
      @root = self.add_node(name)
    else
      @graph = parent.subgraph(qname)
      @root = parent.add_node(name)
    end
    @graph[:truecolor => true]
    @root.shape = 'plaintext'
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
      if process.id =~ %r{^#{qname}} and process.prerequisites.length == 0
        (@root << process.node)[:arrowhead => 'none', :arrowtail => 'none', :dir => 'both', :style => 'invisible']
      end
    end
    
    if @processes.values.select { |p| p.prerequisites.length == 0 }.all? { |p| p.status == 'completed' }
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
    
    attr_reader :name, :status, :node, :prerequisites
    
    def initialize(graph, id, name)
      $stderr.puts id
      @name = name
      @graph = graph
      @node = @graph.add_node(id)
      @node.shape = 'box'
      @node.label = name
      @prerequisites = []
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
        edge = (process.node << @node)
        edge.dir = 'both'
        edge.arrowhead = 'none'
        edge.arrowtail = 'vee'
        if (wf1 != wf2)
          edge.style = 'dashed'
        end
        self.prerequisites << process
      }
      return self
    end
    
    def same_as(process)
      @node = process.node  
    end
    
    def all_prerequisites
      prerequisites.collect { |p| p.all_prerequisites + [p.name] }.flatten.uniq
    end
    
  end

end
