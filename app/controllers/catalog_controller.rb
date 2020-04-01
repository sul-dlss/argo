# frozen_string_literal: true

require 'blacklight/catalog'
class CatalogController < ApplicationController
  include Blacklight::Catalog
  helper ArgoHelper
  include DateFacetConfigurations

  before_action :reformat_dates, :set_user_obj_instance_var
  before_action :show_aspect, only: [:dc, :ds]
  before_action :sort_collection_actions_buttons, only: [:index]
  before_action :limit_facets_on_home_page, only: [:index]

  configure_blacklight do |config|
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder

    # common helper method since search results and reports share most of this config
    BlacklightConfigHelper.add_common_default_solr_params_to_config! config
    config.default_solr_params[:rows] = 10

    config.document_solr_request_handler = '/document'
    # When we test with solr 6 we can have:
    # config.document_solr_path = 'get'
    config.index.document_presenter_class = ArgoIndexPresenter
    config.show.document_presenter_class = ArgoShowPresenter

    config.index.display_type_field = 'content_type_ssim'

    config.show.display_type_field = 'objectType_ssim'

    config.index.thumbnail_method = :render_thumbnail_helper

    config.add_index_field 'id',                              label: 'DRUID'
    config.add_index_field SolrDocument::FIELD_OBJECT_TYPE,   label: 'Object Type'
    config.add_index_field 'content_type_ssim',               label: 'Content Type'
    config.add_index_field SolrDocument::FIELD_APO_ID,        label: 'Admin Policy',      helper_method: :link_to_admin_policy
    config.add_index_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection',        helper_method: :links_to_collections
    config.add_index_field 'project_tag_ssim',                label: 'Project',           link_to_search: true
    config.add_index_field 'source_id_ssim',                  label: 'Source'
    config.add_index_field 'identifier_tesim',                label: 'IDs', helper_method: :value_for_identifier_tesim
    config.add_index_field 'released_to_ssim',                label: 'Released to'
    config.add_index_field 'status_ssi',                      label: 'Status'
    config.add_index_field 'wf_error_ssim',                   label: 'Error', helper_method: :value_for_wf_error

    config.add_show_field 'id',                              label: 'DRUID'
    config.add_show_field SolrDocument::FIELD_OBJECT_TYPE,   label: 'Object Type'
    config.add_show_field 'content_type_ssim',               label: 'Content Type'
    config.add_show_field SolrDocument::FIELD_APO_ID,        label: 'Admin Policy',      helper_method: :link_to_admin_policy_with_objs
    config.add_show_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection',        helper_method: :links_to_collections_with_objs
    config.add_show_field 'project_tag_ssim',                label: 'Project',           link_to_search: true
    config.add_show_field 'source_id_ssim',                  label: 'Source'
    config.add_show_field 'identifier_tesim',                label: 'IDs', helper_method: :value_for_identifier_tesim
    config.add_show_field 'originInfo_date_created_tesim',   label: 'Created'
    config.add_show_field 'preserved_size_dbtsi',            label: 'Preservation Size', helper_method: :preserved_size_human
    config.add_show_field 'tag_ssim',                        label: 'Tags',              link_to_search: true
    config.add_show_field 'released_to_ssim',                label: 'Released to'
    config.add_show_field 'status_ssi',                      label: 'Status'
    config.add_show_field 'wf_error_ssim',                   label: 'Error', helper_method: :value_for_wf_error

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim',               label: 'Tag',                 limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'objectType_ssim',                 label: 'Object Type',         limit: 10
    config.add_facet_field 'content_type_ssim',               label: 'Content Type',        limit: 10
    config.add_facet_field 'content_file_mimetypes_ssim',     label: 'MIME Types',          limit: 10, home: false
    config.add_facet_field 'content_file_roles_ssim',         label: 'File Role',           limit: 10, home: false
    config.add_facet_field 'rights_descriptions_ssim',        label: 'Access Rights',       limit: 1000, sort: 'index', home: false
    config.add_facet_field 'use_license_machine_ssi',         label: 'License',             limit: 10, home: false
    config.add_facet_field 'nonhydrus_collection_title_ssim', label: 'Collection',          limit: 10, more_limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_collection_title_ssim',    label: 'Hydrus Collection',   limit: 10, more_limit: 9999, sort: 'index', home: false
    config.add_facet_field 'nonhydrus_apo_title_ssim',        label: 'Admin Policy',        limit: 10, more_limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_apo_title_ssim',           label: 'Hydrus Admin Policy', limit: 10, more_limit: 9999, sort: 'index', home: false
    config.add_facet_field 'current_version_isi',             label: 'Version',             limit: 10, home: false
    config.add_facet_field 'processing_status_text_ssi',      label: 'Processing Status',   limit: 10, home: false
    config.add_facet_field 'released_to_ssim',                label: 'Released To',         limit: 10
    config.add_facet_field 'wf_wps_ssim',                     label: 'Workflows (WPS)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy'
    config.add_facet_field 'wf_wsp_ssim',                     label: 'Workflows (WSP)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy', home: false
    config.add_facet_field 'wf_swp_ssim',                     label: 'Workflows (SWP)',     limit: 9999, partial: 'blacklight/hierarchy/facet_hierarchy', home: false
    config.add_facet_field 'has_model_ssim',                  label: 'Object Model',        limit: 10, home: false

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', label: 'Object Source', home: false, query: {
      other: {
        label: 'DOR',
        fq: '-has_model_ssim:"info:fedora/afmodel:Hydrus_Item"'\
          ' AND -has_model_ssim:"info:fedora/afmodel:Hydrus_Collection"'\
          ' AND -has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject"'\
          ' AND -has_model_ssim:"info:fedora/dor:googleScannedBook"'
      },

      google: { label: 'Google', fq: 'has_model_ssim:"info:fedora/dor:googleScannedBook"' },

      hydrus: {
        label: 'Hydrus/SDR',
        fq: 'has_model_ssim:"info:fedora/afmodel:Hydrus_Item"'\
          ' OR has_model_ssim:"info:fedora/afmodel:Hydrus_Collection"'\
          ' OR has_model_ssim:"info:fedora/afmodel:Hydrus_AdminPolicyObject"'
      }
    }

    config.add_facet_field 'metadata_source_ssi', label: 'Metadata Source', home: false

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    config.add_facet_field 'empties', label: 'Empty Fields', home: false, query: {
      no_source_id: { label: 'No Source ID', fq: '-source_id_ssim:*' },
      no_rights_characteristics: { label: 'No Rights Characteristics', fq: '-rights_characteristics_ssim:*' },
      no_content_type: { label: 'No Content Type', fq: '-content_type_ssim:*' },
      no_has_model: { label: 'No Object Model', fq: '-has_model_ssim:*' },
      no_objectType: { label: 'No Object Type', fq: '-objectType_ssim:*' },
      no_object_title: { label: 'No Object Title', fq: '-dc_title_ssi:*' },
      no_is_governed_by: { label: 'No APO', fq: "-#{SolrDocument::FIELD_APO_ID}:*" },
      no_collection_title: { label: 'No Collection Title', fq: "-#{SolrDocument::FIELD_COLLECTION_TITLE}:*" },
      no_copyright: { label: 'No Copyright', fq: '-copyright_ssim:*' },
      no_license: { label: 'No License', fq: '-use_license_machine_ssi:*' },
      no_sw_author_ssim: { label: 'No SW Author', fq: '-sw_author_ssim:*' },
      # TODO: mods extent (?)
      # TODO: mods form (?)
      no_sw_genre: { label: 'No SW Genre', fq: '-sw_genre_ssim:*' }, # spec said "mods genre"
      no_sw_language_ssim: { label: 'No SW Language', fq: '-sw_language_ssim:*' },
      no_mods_typeOfResource_ssim: { label: 'No MODS typeOfResource', fq: '-mods_typeOfResource_ssim:*' },
      no_sw_pub_date_sort: { label: 'No SW Date', fq: '-sw_pub_date_sort_ssi:*' },
      no_sw_topic_ssim: { label: 'No SW Topic', fq: '-sw_topic_ssim:*' },
      no_sw_subject_temporal: { label: 'No SW Era', fq: '-sw_subject_temporal_ssim:*' },
      no_sw_subject_geographic: { label: 'No SW Region', fq: '-sw_subject_geographic_ssim:*' },
      no_sw_format: { label: 'No SW Resource Type', fq: '-sw_format_ssim:*' },
      no_use_statement: { label: 'No Use & Reproduction Statement', fq: '-use_statement_ssim:*' }
    }

    config.add_facet_field 'rights_errors_ssim',         label: 'Access Rights Errors', limit: 10, home: false
    config.add_facet_field 'sw_format_ssim',             label: 'SW Resource Type',   limit: 10, home: false
    config.add_facet_field 'sw_pub_date_facet_ssi',      label: 'SW Date',            limit: 10, home: false
    config.add_facet_field 'topic_ssim',                 label: 'SW Topic',           limit: 10, home: false
    config.add_facet_field 'sw_subject_geographic_ssim', label: 'SW Region',          limit: 10, home: false
    config.add_facet_field 'sw_subject_temporal_ssim',   label: 'SW Era',             limit: 10, home: false
    config.add_facet_field 'sw_genre_ssim',              label: 'SW Genre',           limit: 10, home: false
    config.add_facet_field 'sw_language_ssim',           label: 'SW Language',        limit: 10, home: false
    config.add_facet_field 'mods_typeOfResource_ssim',   label: 'MODS Resource Type', limit: 10, home: false

    config.add_facet_fields_to_solr_request! # deprecated in newer Blacklights

    config.add_search_field 'text', label: 'All Fields'
    config.add_sort_field 'id asc', label: 'Druid'
    config.add_sort_field 'score desc', label: 'Relevance'
    config.add_sort_field 'creator_title_ssi asc', label: 'Creator and Title'

    config.spell_max = 5

    config.facet_display = {
      hierarchy: {
        'wf_wps' => [['ssim'], ':'],
        'wf_wsp' => [['ssim'], ':'],
        'wf_swp' => [['ssim'], ':'],
        'exploded_tag' => [['ssim'], ':']
      }
    }

    config.add_results_collection_tool(:report_view_toggle)
    config.add_results_collection_tool(:bulk_update_view_button)
    config.add_results_collection_tool(:bulk_action_button)

    ##
    # Configure document actions framework
    config.index.document_actions.delete(:bookmark)

    config.show.partials = %w(show_header full_view_links thumbnail show datastreams events cocina history contents techmd)
  end

  def default_solr_doc_params(id = nil)
    id ||= params[:id]
    {
      q: %(id:"#{id}")
    }
  end

  def index
    @presenter = HomeTextPresenter.new(current_user)
    super
  end

  def show
    params[:id] = 'druid:' + params[:id] unless params[:id].include? 'druid'
    @obj = Dor.find params[:id]
    authorize! :view_metadata, @obj
    @response, @document = fetch params[:id]

    object_client = Dor::Services::Client.object(params[:id])

    # Used for drawing releaseTags in the history section
    begin
      @cocina = object_client.find
    rescue Dor::Services::Client::UnexpectedResponse
      @cocina = NilModel.new(params[:id])
    end
    @events = object_client.events.list

    @milestones = MilestoneService.milestones_for(druid: params[:id])

    @buttons_presenter = ButtonsPresenter.new(
      ability: current_ability,
      solr_document: @document,
      object: @obj
    )

    @techmd = TechmdService.techmd_for(druid: params[:id]) if params[:beta]

    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  def dc
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def ds
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def manage_release
    authorize! :manage_item, Dor.find(params[:id])
    @response, @document = fetch params[:id]
    @bulk_action = BulkAction.new

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def show_aspect
    pid = params[:id].include?('druid') ? params[:id] : "druid:#{params[:id]}"
    @obj ||= Dor.find(pid)
    @response, @document = fetch pid
  end

  def set_user_obj_instance_var
    @user = current_user
  end

  def reformat_dates
    params.each do |key, val|
      next unless key =~ /_datepicker/ && val =~ /[0-9]{2}\/[0-9]{2}\/[0-9]{4}/

      val = DateTime.parse(val).beginning_of_day.utc.xmlschema
      field = key.split('_after_datepicker').first.split('_before_datepicker').first
      params[:f][field] = '[' + val.to_s + 'Z TO *]'
    rescue
    end
  end

  # Sorts the Blacklight collection actions buttons so that the "Bulk Action" and "Bulk Update View" buttons appear
  # at the front of the list.
  def sort_collection_actions_buttons
    collection_actions_order = blacklight_config.index.collection_actions.keys
    collection_actions_order.delete(:bulk_update_view_button)
    collection_actions_order.insert(0, :bulk_update_view_button)
    collection_actions_order.delete(:bulk_action_button)
    collection_actions_order.insert(1, :bulk_action_button)

    # Use the order of indices in the collection_actions_order array for the Blacklight hash
    blacklight_config.index.collection_actions = blacklight_config.index.collection_actions.to_h.sort do |(key1, _value1), (key2, _value2)|
      collection_actions_order.index(key1) <=> collection_actions_order.index(key2)
    end
  end

  def limit_facets_on_home_page
    return if has_search_parameters? || params[:all]

    blacklight_config.facet_fields.each do |_k, v|
      v.include_in_request = false if v.home == false
    end
  end
end
