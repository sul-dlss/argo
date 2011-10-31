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
    @obj = Dor::Base.load_instance params[:id]
    if @obj.datastreams_in_fedora.keys.include?(params[:dsid])
      @ds = @obj.datastreams[params[:dsid]]
      data = @ds.content
      if @ds.attributes['mimeType'] =~ /xml$/ and not params[:raw]
        begin
          doc = Nokogiri::XML(data)
          xslt = Nokogiri::XSLT(File.read(File.join(Rails.root, 'lib/identity.xsl')))
          data = xslt.transform(doc).to_xml
        rescue
          # Leave the data the way it is if it can't be transformed
        end
      end
      send_data data, :type => @ds.attributes['mimeType'], :disposition => 'inline'
    else
      raise ActionController::RoutingError.new('Not Found')
    end
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
    raise ActionController::RoutingError.new('Not Found') if @graph.nil?
    @graph['rankdir'] = params[:dir] || 'TB'
    format = params[:format].to_sym
    if [:gv,:dot].include?(format)
      send_data @graph.to_s, :type => 'text/x-graphviz'
    else
      mimetype = Rack::Mime.mime_type(".#{format}")
      send_data @graph.output(format => String), :type => mimetype, :disposition => 'inline'
    end
  end
  
  private
  def render_workflow_graph(rec,wf,g = nil)
    workflow = Dor::WorkflowObject.find_by_name(wf)
    return nil if workflow.nil?
    graph = workflow.graph(g)
    unless graph.nil?
      rec['wf_wps_facet'].each do |facet|
        (wf_name,process,status) = facet.split(/:/)
        if (wf_name == wf) and not status.nil?
          if graph.processes[process]
            graph.processes[process].status = status
          end
        end
      end
    end
    graph.finish
  end
  
end 
