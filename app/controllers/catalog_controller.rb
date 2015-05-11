# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class CatalogController < ApplicationController
  include Blacklight::Marc::Catalog

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
      :qf => %{text^3 citationCreator_t citationTitle_t content_file_t coordinates_teim creator_tesim dc_creator_si dc_identifier_t dc_title_si dor_id_tesim event_t events_event_t events_t extent_teim identifier_tesim identityMetadata_citationCreator_t identityMetadata_citationTitle_t objectCreator_teim identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_teim originInfo_place_placeTerm_tesim originInfo_publisher_tesim obj_label_teim obj_state_teim originInfo_place_placeTerm_tesim originInfo_publisher_tesim otherId_t public_dc_contributor_tesim public_dc_coverage_tesim public_dc_creator_tesim public_dc_date_tesim public_dc_description_tesim public_dc_format_tesim public_dc_identifier_tesim public_dc_language_tesim public_dc_publisher_tesim public_dc_relation_tesim public_dc_rights_tesim public_dc_subject_tesim public_dc_title_tesim public_dc_type_tesim scale_teim shelved_content_file_t sourceId_t tag_ssim title_tesim topic_tesim},
      :rows => 10,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_ssim.facet.limit' => -1,
      :'f.wf_wsp_ssim.facet.limit' => -1,
      :'f.wf_swp_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.limit' => -1,
      :'f.tag_ssim.facet.sort' => 'index'
    }

    config.index.title_field = 'id'
    config.index.display_type_field = 'content_type_ssim'

    config.show.title_field  = 'obj_label_t'
    config.show.display_type_field = 'objectType_t'
    config.show.sections = {
      :default => ['identification','datastreams','history','contents'],
      :item    => ['identification','datastreams','history','contents','child_objects']
    }
    config.show.section_links = {
      'identification' => :render_full_view_links,
      'contents'       => :render_dor_workspace_link
    }

    config.add_index_field 'id',              :label => 'DRUID'
    config.add_index_field 'dc_creator_si',   :label => 'Creator'
    config.add_index_field 'project_tag_ssim',:label => 'Project'

    config.add_show_field 'content_type_ssim',           :label => 'Content Type'
    config.add_show_field 'identifier_tesim',            :label => 'IDs'
    # config.add_show_field 'objProfile_objCreateDate_dt', :label => 'Created:'  # TODO: not sure objProfile fields exist
    # config.add_show_field 'objProfile_objLabel_dt',      :label => 'Label:'
    config.add_show_field 'is_governed_by_ssim',         :label => 'Admin Policy'
    config.add_show_field 'is_member_of_collection_ssim',:label => 'Collection'
    config.add_show_field 'status_ssm',                  :label => 'Status'
    config.add_show_field 'objectType_ssim',             :label => 'Object Type'
    config.add_show_field 'id',                          :label => 'DRUID'
    config.add_show_field 'project_tag_ssim',            :label => 'Project'
    config.add_show_field 'source_id_ssim',              :label => 'Source'
    config.add_show_field 'tag_ssim',                    :label => 'Tags'
    config.add_show_field 'wf_error_ssim',                :label => "Error"
    config.add_show_field 'collection_title_ssim',       :label => "Collection Title"
    config.add_show_field 'metadata_source_ssi',         :label => 'MD Source'
    config.add_show_field 'preserved_size_ssm',          :label => "Preservation Size"

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim', :label => 'Tag', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_ssim',       :label => 'Object Type'
    config.add_facet_field 'content_type_ssim',     :label => 'Content Type'
    #TODO: access_rights_ssim once solr has it
    config.add_facet_field 'collection_title_ssim', :label => 'Collection',  :sort => 'index', :limit => 500
    config.add_facet_field 'apo_title_ssim',        :label => 'Admin Policy',:sort => 'index', :limit => 500
    config.add_facet_field 'current_version_isi',   :label => 'Version'
    #TODO: processing_status_ssi once solr has it
    #TODO: release_status_ssim once solr has it
    #TODO: does release_status and processing_status supersede lifecycle?  do we ditch that?
    config.add_facet_field 'lifecycle_ssim', :label => 'Lifecycle'
    config.add_facet_field 'wf_wps_ssim', :label => 'Workflows (WPS)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_ssim', :label => 'Workflows (WSP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_swp_ssim', :label => 'Workflows (SWP)', :partial => 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'has_model_ssim',  :label => 'Object Model'

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', :label => 'Object Source', :query => {
      :other  => { :label => 'DOR',        :fq => '-has_model_ssim:"info:fedora/afmodel:Hydrus_Item" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" AND -has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject" AND -has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :google => { :label => 'Google',     :fq => 'has_model_ssim:"info:fedora/dor:googleScannedBook"' },
      :hyrdus => { :label => 'Hydrus/SDR', :fq => 'has_model_ssim:"info:fedora/afmodel:Hydrus_Item" OR has_model_ssim:"info:fedora/afmodel:Hydrus_Collection" OR has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject"' }
    }

    config.add_facet_field 'metadata_source_ssi', :label => 'Metadata Source'

    config.add_facet_field 'empties', :label => 'Empty Fields', :query => {
      :no_has_model => { :label => 'has_model_ssim',  :fq => "-has_model_ssim:*"}
    }

    # Be careful using NOW: http://lucidworks.com/blog/date-math-now-and-filter-queries/
    # tl;dr: specify coarsest granularity (/DAY or /HOUR) or lose caching
    #
    #TODO: update blacklight_range_limit to work w/ dates and use it.  Or something similarly powerful.
    #      Per-query user-paramatized facet endpoints w/ auto-scaling granularity is the point.
    #      See solr facet ranges (start/end/gap), NOT facet range queries (fq), as here.
    config.add_facet_field 'registered_date', :label => 'Registered', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "registered_dttsim:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "registered_dttsim:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'submitted_date', :label => 'Submitted', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "submitted_dttsim:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "submitted_dttsim:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'published_date', :label => 'Published', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "published_dttsim:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "published_dttsim:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'deposited_date', :label => 'Deposited', :query => {
      :days_1  => { :label => 'today',          :fq => "deposited_dttsim:[NOW/DAY TO *]"},
      :days_7  => { :label => 'within 7 days',  :fq => "deposited_dttsim:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "deposited_dttsim:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'object_modified_day', :label => 'Object Last Modified', :query => {
      :days_7  => { :label => 'within 7 days',  :fq => "modified_latest_dttsi:[NOW/DAY-7DAYS TO *]"},
      :days_30 => { :label => 'within 30 days', :fq => "modified_latest_dttsi:[NOW/DAY-30DAYS TO *]"}
    }
    config.add_facet_field 'version_opened', :label => 'Open Version', :query => {
      :all     => { :label => 'All',               :fq => "opened_latest_dttsi:*"},
      :days_7  => { :label => 'more than 7 days',  :fq => "opened_latest_dttsi:[* TO NOW/DAY-7DAYS]"},
      :days_30 => { :label => 'more than 30 days', :fq => "opened_latest_dttsi:[* TO NOW/DAY-30DAYS]"}
    }

    config.add_facet_fields_to_solr_request!        # deprecated in newer Blacklights

    config.add_search_field 'text', :label => 'All Fields'
    config.add_sort_field 'id asc', :label => 'Druid'
    config.add_sort_field 'score desc', :label => 'Relevance'
    config.add_sort_field 'creator_title_si asc', :label => 'Creator and Title'

    config.spell_max = 5

    config.facet_display = {
      :hierarchy => {
        'wf' => [['wps','wsp','swp'], ':'],
        'tag' => [[nil], ':']
      }
    }

    config.field_groups = {
      :identification => [
        ['id','objectType_ssim','content_type_ssim','status_ssm','wf_error_ssim'],
        ['is_governed_by_ssim','is_member_of_collection_ssim','project_tag_ssim','source_id_ssim','preserved_size_ssm']
      ],
      :full_identification => [
        ['id','objectType_ssim','content_type_ssim','metadata_source_ssim'],
        ['is_governed_by_ssim','is_member_of_collection_ssim','project_tag_ssim','source_id_ssim']
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
        if (key=~ /_datepicker/ and val=~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/)
          val = DateTime.parse(val).beginning_of_day.utc.xmlschema
          field = key.split( '_after_datepicker').first.split('_before_datepicker').first
          params[:f][field] = '['+val.to_s+'Z TO *]'
        end
      rescue
      end
    end
  end
end
