# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'graphviz'

class CatalogController < ApplicationController  

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  helper ArgoHelper
  helper HierarchyHelper
  
  configure_blacklight do |config|
    config.default_solr_params = {
      :q => "*:*",
      :rows => 10,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_facet.facet.limit' => -1,
      :'f.wf_wsp_facet.facet.limit' => -1,
      :'f.wf_swp_facet.facet.limit' => -1
    }
    
    config.index.show_link = 'id'
    config.index.record_display_type = 'content_type_facet'
    
    config.show.html_title = 'obj_label_t'
    config.show.heading = 'obj_label_t'
    config.show.display_type = 'objectType_t'
    config.show.sections = {
      :default => ['identification','datastreams','history'],
      :item    => ['identification','datastreams','history','contents','child_objects']
    }
    config.show.section_links = {
      'identification' => :render_full_dc_link,
      'contents' => :render_dor_workspace_link
    }
    
    config.add_index_field 'id', :label => 'DRUID:'
    config.add_index_field 'dc_creator_t', :label => 'Creator:'
    config.add_index_field 'project_tag_t', :label => 'Project:'
    
    config.add_show_field 'content_type_facet', :label => 'Content Type:'
    config.add_show_field 'dc_identifier_t', :label => 'IDs:'
    config.add_show_field 'obj_createdDate_dt', :label => 'Created:'
    config.add_show_field 'obj_label_t', :label => 'Label:'
    config.add_show_field 'is_governed_by_s', :label => 'Admin. Policy:'
    config.add_show_field 'is_member_of_collection_s', :label => 'Collection:'
    config.add_show_field 'item_status_t', :label => 'Status:'
    config.add_show_field 'objectType_t', :label => 'Object Type:'
    config.add_show_field 'id', :label => 'DRUID:'
    config.add_show_field 'project_tag_t', :label => 'Project:'
    config.add_show_field 'source_id_t', :label => 'Source:'
    config.add_show_field 'tag_t', :label => 'Tags:'
    
    config.add_facet_field 'tag_facet', :label => 'Tag', :partial => 'facet_hierarchy'
    config.add_facet_field 'objectType_t', :label => 'Object Type'
    config.add_facet_field 'content_type_facet', :label => 'Content Type'
    config.add_facet_field 'is_governed_by_s', :label => 'Admin. Policy'
    config.add_facet_field 'is_member_of_collection_s', :label => 'Owning Collection'
    config.add_facet_field 'lifecycle_facet', :label => 'Lifecycle'
    config.add_facet_field 'wf_wps_facet', :label => 'Workflows (WPS)', :partial => 'facet_hierarchy'
    config.add_facet_field 'wf_wsp_facet', :label => 'Workflows (WSP)', :partial => 'facet_hierarchy'
    config.add_facet_field 'wf_swp_facet', :label => 'Workflows (SWP)', :partial => 'facet_hierarchy'
    
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    
    config.add_search_field 'text', :label => 'All Fields'
    
    config.add_sort_field 'score desc', :label => 'Relevance'
    
    config.spell_max = 5
    
    config.facet_display = {
      :hierarchy => {
        'wf' => ['wps','wsp','swp'],
        'tag' => [nil]
      }
    }
    
    config.field_groups = {
      :identification => [
        ['id','objectType_t','content_type_facet','item_status_t'],
        ['is_governed_by_s','is_member_of_collection_s','project_tag_t','source_id_t']
      ]
    }
  end
  
  def solr_doc_params(id=nil)
    id ||= params[:id]
    {
      :q => %{id:"#{id}"}
    }
  end

  def datastream_view
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor.find params[:id], :lightweight => true
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
    @obj = Dor.find params[:id], :lightweight => true
    render :layout => request.xhr? ? false : true
  end
  
  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    render :partial => 'catalog/workflow_grid'
  end
  
  def workflow_view
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor.find params[:id], :lightweight => true
    @workflow_id = params[:wf_name]
    @workflow = @workflow_id == 'workflow' ? @obj.workflows : @obj.workflows[@workflow_id]

    respond_to do |format|
      format.html
      format.xml  { render :xml => @workflow.ng_xml.to_xml }
      format.any(:png,:svg,:jpeg) {
        graph = @workflow.graph
        raise ActionController::RoutingError.new('Not Found') if graph.nil?
        image_data = graph.output(request.format.to_sym => String)
        send_data image_data, :type => request.format.to_s, :disposition => 'inline'
      }
    end
  end
end 
