# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class CatalogController < ApplicationController  

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  include Argo::AccessControlsEnforcement
  #include BlacklightFacetExtras::Query::ControllerExtension
  helper ArgoHelper

  before_filter :reformat_dates, :set_user_obj_instance_var

  CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params

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
      :'f.tag_facet.facet.sort' => 'index'
    }

    config.index.show_link = 'id'
    config.index.record_display_type = 'content_type_facet'

    config.show.html_title   = 'obj_label_t'
    config.show.heading      = 'obj_label_t'
    config.show.display_type = 'objectType_t'
    config.show.sections = {
      :default => ['identification','datastreams','history','contents'],
      :item    => ['identification','datastreams','history','contents','child_objects']
    }
    config.show.section_links = {
      'identification' => :render_full_view_links,
      'contents'       => :render_dor_workspace_link
    }

    config.add_index_field 'id',            :label => 'DRUID:'
    config.add_index_field 'dc_creator_t',  :label => 'Creator:'
    config.add_index_field 'project_tag_t', :label => 'Project:'
    config.add_show_field 'content_type_facet',          :label => 'Content Type:'
    config.add_show_field 'embargoMetadata_t',           :label => 'Embargo:'
    config.add_show_field 'identifier_t',                :label => 'IDs:'
    config.add_show_field 'objProfile_objCreateDate_dt', :label => 'Created:'
    config.add_show_field 'objProfile_objLabel_dt',      :label => 'Label:'
    config.add_show_field 'is_governed_by_s',            :label => 'Admin. Policy:'
    config.add_show_field 'is_member_of_collection_s',   :label => 'Collection:'
    config.add_show_field 'item_status_t',               :label => 'Status:'
    config.add_show_field 'objectType_t',                :label => 'Object Type:'
    config.add_show_field 'id',                          :label => 'DRUID:'
    config.add_show_field 'project_tag_t',               :label => 'Project:'
    config.add_show_field 'source_id_t',                 :label => 'Source:'
    config.add_show_field 'identityMetadata_tag_t',      :label => 'Tags:'
    config.add_show_field 'status_display',              :label => 'Status:'
    config.add_show_field 'wf_error_display',            :label => "Error:"
    config.add_show_field 'collection_title_display',    :label => "Error:"
    config.add_show_field 'metadata_source_t',           :label => 'MD Source:'
    config.add_show_field 'preserved_size_display',      :label => "Preservation Size"

    config.add_facet_field 'tag_facet', :label => 'Tag', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_facet',       :label => 'Object Type'
    config.add_facet_field 'content_type_facet',     :label => 'Content Type'
    config.add_facet_field 'collection_title_facet', :label => 'Collection', :sort => 'index', :limit => 500
    config.add_facet_field 'hydrus_collection_title_facet', :label => 'Hydrus Collection', :sort => 'index', :limit => 500
    config.add_facet_field 'apo_title_facet',        :label => 'Admin. Policy',        :sort => 'index', :limit => 500
    config.add_facet_field 'hydrus_apo_title_facet', :label => 'Hydrus Admin. Policy', :sort => 'index', :limit => 500
    config.add_facet_field 'lifecycle_facet', :label => 'Lifecycle'
    config.add_facet_field 'wf_wps_facet', :label => 'Workflows (WPS)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_facet', :label => 'Workflows (WSP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_swp_facet', :label => 'Workflows (SWP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'has_model_s',  :label => 'Model', :helper_method => :model_facet_helper  # helper_method requires Blacklight 4.2

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', :label => 'Source', :query => {
      :other  => { :label => 'DOR',        :fq => '-has_model_s:"info:fedora/afmodel:Hydrus_Item" AND -has_model_s:"info:fedora/afmodel:Hydrus_Collection" AND -has_model_s:"info:fedora/afmodel:Hydrus_AdminPolicyObject" AND -has_model_s:"info:fedora/dor:googleScannedBook"' },
      :google => { :label => 'Google',     :fq => 'has_model_s:"info:fedora/dor:googleScannedBook"' },
    # :deepen => { :label => 'DPN',        :fq => 'has_model_s:info%3Afedora/whatever' },
      :hyrdus => { :label => 'Hydrus/SDR', :fq => 'has_model_s:"info:fedora/afmodel:Hydrus_Item" OR has_model_s:"info:fedora/afmodel:Hydrus_Collection" OR has_model_s:"info:fedora/afmodel:Hydrus_AdminPolicyObject"' }
    }

    config.add_facet_field 'current_version_facet', :label => 'Version'

    config.add_facet_field 'empties', :label => 'Empty Fields', :query => {
      :no_has_model => { :label => 'has_model_s',  :fq => "-has_model_s:*"}
    }
    config.add_facet_field 'registered_date', :label => 'Registered', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "registered_day_facet:[#{ 7.days.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "registered_day_facet:[#{30.days.ago.utc.xmlschema.split('T').first } TO *]"}
    }
    config.add_facet_field 'submitted_date', :label => 'Submitted', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "submitted_day_facet:[#{ 7.days.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "submitted_day_facet:[#{30.days.ago.utc.xmlschema.split('T').first } TO *]"}
    }
    config.add_facet_field 'published_date', :label => 'Published', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "published_day_facet:[#{ 7.days.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "published_day_facet:[#{30.days.ago.utc.xmlschema.split('T').first } TO *]"}
    }
    config.add_facet_field 'deposited_date', :label => 'Deposited', :query => {
      :days_1  => { :label => 'today',          :fq => "deposited_day_facet:[#{ 1.minute.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_7  => { :label => 'within 7 days',  :fq => "deposited_day_facet:[#{ 7.days.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "deposited_day_facet:[#{30.days.ago.utc.xmlschema.split('T').first } TO *]"}
    }
    config.add_facet_field 'object_modified_day', :label => 'Object Last Modified', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "last_modified_day_facet:[#{ 7.days.ago.utc.xmlschema.split('T').first } TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "last_modified_day_facet:[#{30.days.ago.utc.xmlschema.split('T').first } TO *]"}
    }
    config.add_facet_field 'version_opened', :label => 'Open Version', :query => {
      :all     => { :label => 'All',               :fq => "version_opened_facet:[* TO #{1.second.ago.utc.xmlschema.split('T').first }]"},
      :days_7  => { :label => 'more than 7 days',  :fq => "version_opened_facet:[* TO #{ 7.days.ago.utc.xmlschema }]"},
      :days_30 => { :label => 'more than 30 days', :fq => "version_opened_facet:[* TO #{30.days.ago.utc.xmlschema }]"}
    }

    config.add_facet_fields_to_solr_request!        # deprecated in newer Blacklights

    config.add_search_field 'text', :label => 'All Fields'
    config.add_sort_field 'id asc', :label => 'Druid'
    config.add_sort_field 'score desc', :label => 'Relevance'
    config.add_sort_field 'creator_title_sort asc', :label => 'Creator and Title'

    config.spell_max = 5

    config.facet_display = {
      :hierarchy => {
        'wf' => ['wps','wsp','swp'],
        'tag' => [nil]
      }
    }

    config.field_groups = {
      :identification => [
        ['id','objectType_t','content_type_facet','status_display','wf_error_display'],
        ['is_governed_by_s','is_member_of_collection_s','project_tag_t','source_id_t','preserved_size_display']
      ],
      :full_identification => [
        ['id','objectType_t','content_type_facet','metadata_source_t'],
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

  def show
    params[:id] = 'druid:' + params[:id] if not params[:id].include? 'druid'
    @obj = Dor.find params[:id]
    apo = nil
    begin
      @apo = @obj.admin_policy_object
    rescue
    end
    if not @apo and not @user.is_admin and not @user.is_viewer
      render :status=> :forbidden, :text =>'No APO, no access'
      return
    end
    #if there is no apo and things got to this point, they are a repo viewer or admin
    if @apo and not @obj.can_view_metadata?(@user.roles(@apo.pid)) and not @user.is_admin and not @user.is_viewer
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
    super()
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
    if @obj.nil?
      obj_pid = params[:id].include?('druid') ? params[:id] : 'druid:' + params[:id]
      @obj = Dor.find obj_pid
    end
    @response, @document = get_solr_response_for_doc_id
    render :layout => request.xhr? ? false : true
  end

  private
  def set_user_obj_instance_var
    @user = current_user
  end

  def reformat_dates
    params.each do |key, val|
      begin
        if (key=~  /_datepicker/ and val=~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/)
          val = DateTime.parse(val).beginning_of_day.utc.xmlschema
          field = key.split( '_after_datepicker').first.split('_before_datepicker').first
          params[:f][field] = '['+val.to_s+'Z TO *]'
        end
      rescue
      end
    end
  end
end
