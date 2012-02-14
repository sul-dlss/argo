# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'graphviz'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  helper HierarchyHelper
  
  def solr_doc_params(id=nil)
    id ||= params[:id]
    {
      :q => %{PID:"#{id}"}
    }
  end

  def datastream_view
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor::Base.load params[:id], @document['objectType_t'].to_s
    ds = @obj.datastreams[params[:dsid]]
    data = @obj.content params[:dsid], params[:raw]
    unless data.nil?
      send_data data, :type => ds.attributes['mimeType'], :disposition => 'inline'
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end
  
  def show_aspect
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor::Base.load params[:id], @document['objectType_t'].to_s
    render :layout => request.xhr? ? false : true
  end
  
  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    render :partial => 'catalog/workflow_grid'
  end
  
  def workflow_view
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor::Base.load params[:id], @document['objectType_t'].to_s
    @workflow = @obj.datastreams[params[:wf_name]]
    format = params[:format]
    if Constants::FORMATS.include?(format)
      mimetype = Rack::Mime.mime_type(".#{format}")
      graph = workflow_graph(params[:wf_name], params[:dir])
      send_data graph.output(format.to_sym => String), :type => mimetype, :disposition => 'inline'
    else
      render
    end
  end
  
  def workflow_graph(wf_name, dir)
    if wf_name == 'workflow'
      graph = GraphViz.digraph(@obj.pid)
      sg = graph.add_graph('rank') { |g| g[:rank => 'same'] }
      document_workflows = @document['wf_wps_facet'].collect { |val| val.split(/:/).first }.uniq
      document_workflows.each do |wf_name|
        wf = @obj.workflow(wf_name)
        unless wf.nil?
          g = wf.graph(graph)
          sg.add_node(g.root.id) unless g.nil?
        end
      end
    else
      graph = @obj.datastreams[wf_name].graph
    end
    raise ActionController::RoutingError.new('Not Found') if graph.nil?
    graph['rankdir'] = dir || 'TB'
    graph
  end

end 
