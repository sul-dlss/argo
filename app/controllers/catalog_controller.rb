# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'wf_viz'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  helper HierarchyHelper

  def solr_doc_params(id=nil)
    id ||= params[:id]
    {
      :q => %{PID:"#{id}"}
    }
  end

  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    render :partial => 'catalog/workflow_grid'
  end
  
  def workflow_graph
    @response, @document = get_solr_response_for_doc_id
    if params[:wf_name] == 'workflow'
      @graph = GraphViz.digraph(params[:id])
      sg = @graph.add_graph('rank') { |g| g[:rank => 'same'] }
      document_workflows = @document['wf_wps_facet'].collect { |val| val.split(/:/).first }.uniq
      document_workflows.each do |wf_name|
        g = render_workflow_graph(@document,wf_name,@graph)
        sg.add_node(g.root.id) unless g.nil?
      end
    else
      @graph = render_workflow_graph(@document,params[:wf_name])
    end
    @graph['rankdir'] = params[:dir] || 'TB'
    raise ActionController::RoutingError.new('Not Found') if @graph.nil?
    format = params[:format].to_sym
    @graph.output(:none => "#{params[:format]}.gv")
    send_data @graph.output(format => String), :type => Rack::Mime.mime_type(".#{format}"), :disposition => 'inline'
  end
  
  private
  def render_workflow_graph(rec,wf,g = nil)
    workflow = Workflow.find(wf)
    return nil if workflow.nil?
    graph = workflow.graph(g)
    unless graph.nil?
      rec['wf_wps_facet'].each do |facet|
        (workflow,process,status) = facet.split(/:/)
        if (workflow == wf) and not status.nil?
          if graph.processes[process]
            graph.processes[process].status = status
          end
        end
      end
    end
    graph
  end
  
end 
