# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  #include BlacklightFacetExtras::Query::ControllerExtension
  helper ArgoHelper
  
before_filter :reformat_dates




  configure_blacklight do |config|
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 citationCreator_t citationTitle_t content_file_t coordinates_t creator_t dc_creator_t dc_identifier_t dc_title_t dor_id_t event_t events_event_t events_t extent_t identifier_t identityMetadata_citationCreator_t identityMetadata_citationTitle_t identityMetadata_objectCreator_t identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_t mods_originInfo_place_placeTerm_t mods_originInfo_publisher_t obj_label_t obj_state_t originInfo_place_placeTerm_t originInfo_publisher_t otherId_t public_dc_contributor_t public_dc_coverage_t public_dc_creator_t public_dc_date_t public_dc_description_t public_dc_format_t public_dc_identifier_t public_dc_language_t public_dc_publisher_t public_dc_relation_t public_dc_rights_t public_dc_subject_t public_dc_title_t public_dc_type_t scale_t shelved_content_file_t sourceId_t tag_t title_t topic_t},
      :rows => 10,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_facet.facet.limit' => -1,
      :'f.wf_wsp_facet.facet.limit' => -1,
      :'f.wf_swp_facet.facet.limit' => -1,
      :'f.tag_facet.facet.limit' => -1,
      :'f.is_member_of_collection_s.facet.limit' => -1,
      :'f.tag_facet.facet.sort' => 'index'
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
    config.add_show_field 'embargoMetadata_t', :label => 'Embargo:'
    config.add_show_field 'identifier_t', :label => 'IDs:'
    config.add_show_field 'objProfile_objCreateDate_dt', :label => 'Created:'
    config.add_show_field 'objProfile_objLabel_dt', :label => 'Label:'
    config.add_show_field 'is_governed_by_s', :label => 'Admin. Policy:'
    config.add_show_field 'is_member_of_collection_s', :label => 'Collection:'
    config.add_show_field 'item_status_t', :label => 'Status:'
    config.add_show_field 'objectType_t', :label => 'Object Type:'
    config.add_show_field 'id', :label => 'DRUID:'
    config.add_show_field 'project_tag_t', :label => 'Project:'
    config.add_show_field 'source_id_t', :label => 'Source:'
    config.add_show_field 'tag_t', :label => 'Tags:'
    
    config.add_facet_field 'tag_facet', :label => 'Tag', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_facet', :label => 'Object Type'
    config.add_facet_field 'content_type_facet', :label => 'Content Type'
    config.add_facet_field 'is_governed_by_s', :label => 'Admin. Policy'
    config.add_facet_field 'is_member_of_collection_s', :label => 'Collection'
    config.add_facet_field 'lifecycle_facet', :label => 'Lifecycle'
    config.add_facet_field 'wf_wps_facet', :label => 'Workflows (WPS)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_facet', :label => 'Workflows (WSP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_swp_facet', :label => 'Workflows (SWP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'indexed_at_dt', :label => 'Last Argo Update'
    config.add_facet_field 'registered_dt',:label =>'Registered'
    config.add_facet_field 'submitted_dt',:label =>'Submitted'
    config.add_facet_field 'published_dt',:label =>'Published'
    
    config.add_facet_field 'indexed_at_date', :label => 'Last Argo Update', :query => {
        :days_7 => { :label => 'within 7 days', :fq => "indexed_at_dt:[#{7.days.ago.utc.xmlschema } TO *]" },
        :days_30 => { :label => 'within 30 days', :fq => "indexed_at_dt:[#{30.days.ago.utc.xmlschema } TO *]"}
      }
     config.add_facet_field 'submitted_date', :label => 'Submitted', :query => {
        :days_7 => { :label => 'within 7 days', :fq => "submitted_dt:[#{7.days.ago.utc.xmlschema } TO *]" },
        :days_30 => { :label => 'within 30 days', :fq => "submitted_dt:[#{30.days.ago.utc.xmlschema } TO *]"}
      }
          config.add_facet_field 'published_date', :label => 'Published', :query => {
        :days_7 => { :label => 'within 7 days', :fq => "published_dt:[#{7.days.ago.utc.xmlschema } TO *]" },
        :days_30 => { :label => 'within 30 days', :fq => "published_dt:[#{30.days.ago.utc.xmlschema } TO *]"}
      }
          config.add_facet_field 'registered_date', :label => 'Registered', :query => {
        :days_7 => { :label => 'within 7 days', :fq => "registered_dt:[#{7.days.ago.utc.xmlschema } TO *]" },
        :days_30 => { :label => 'within 30 days', :fq => "registered_dt:[#{30.days.ago.utc.xmlschema } TO *]"}
      }
      config.add_facet_fields_to_solr_request!
    
    config.add_search_field 'text', :label => 'All Fields'
    
    config.add_sort_field 'score desc', :label => 'Relevance'
    #These 2 lines make the sort dropdowns appear, but the queries cause an ArrayOutOfBoundsException in solr
    config.add_sort_field 'creator_sort desc', :label => 'Creator'
    config.add_sort_field 'title_sort desc', :label => 'Title'
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
    data = @obj.datastreams[params[:dsid]].content 
    unless data.nil?
      send_data data, :type => 'xml', :disposition => 'inline'
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end
  
  def show_aspect
    @response, @document = get_solr_response_for_doc_id
    @obj = Dor.find params[:id]
    render :layout => request.xhr? ? false : true
  end
  private
  def reformat_dates
    params.each do |key, val|
    begin 
		 if(key=~  /_datepicker/ and val=~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/)
        val= DateTime.parse(val).beginning_of_day.utc.xmlschema
				field=key.split( '_after_datepicker').first.split('_before_datepicker').first
				params[:f][field]='['+val.to_s+'Z TO *]'
      end
     rescue
		 end
  end
end
end
