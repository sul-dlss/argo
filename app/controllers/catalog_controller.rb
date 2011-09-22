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
    graph = render_workflow_graph(@document,params[:wf_name])
    format = params[:format].to_sym
    send_data graph.output(format => String), :type => Rack::Mime.mime_type(".#{format}"), :disposition => 'inline'
  end
  
  private
  def render_workflow_graph(rec,wf)
    config_file = File.join(Rails.root,'config/workflows',wf)+'.yaml'
    graph = File.exists?(config_file) ? WorkflowViz.from_config(wf,YAML.load(File.read(config_file))) : nil

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
