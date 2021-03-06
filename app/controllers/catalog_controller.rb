# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class CatalogController < ApplicationController
  include Blacklight::Catalog
  helper ArgoHelper
  include DateFacetConfigurations

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

    config.index.display_type_field = SolrDocument::FIELD_CONTENT_TYPE

    config.show.display_type_field = 'objectType_ssim'

    config.index.thumbnail_method = :render_thumbnail_helper

    config.add_index_field 'id',                              label: 'DRUID'
    config.add_index_field SolrDocument::FIELD_OBJECT_TYPE,   label: 'Object Type'
    config.add_index_field SolrDocument::FIELD_CONTENT_TYPE,  label: 'Content Type'
    config.add_index_field SolrDocument::FIELD_APO_ID,        label: 'Admin Policy',      helper_method: :link_to_admin_policy
    config.add_index_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection',        helper_method: :links_to_collections
    config.add_index_field 'project_tag_ssim',                label: 'Project',           link_to_facet: true
    config.add_index_field 'source_id_ssim',                  label: 'Source'
    config.add_index_field 'identifier_tesim',                label: 'IDs', helper_method: :value_for_identifier_tesim
    config.add_index_field SolrDocument::FIELD_RELEASED_TO,   label: 'Released to'
    config.add_index_field 'status_ssi',                      label: 'Status'
    config.add_index_field 'wf_error_ssim',                   label: 'Error', helper_method: :value_for_wf_error
    config.add_index_field 'rights_descriptions_ssim',        label: 'Access Rights'

    config.add_show_field 'id',                              label: 'DRUID'
    config.add_show_field SolrDocument::FIELD_OBJECT_TYPE,   label: 'Object Type'
    config.add_show_field SolrDocument::FIELD_CONTENT_TYPE,  label: 'Content Type'
    config.add_show_field SolrDocument::FIELD_APO_ID,        label: 'Admin Policy',      helper_method: :link_to_admin_policy_with_objs
    config.add_show_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection',        helper_method: :links_to_collections_with_objs
    config.add_show_field 'project_tag_ssim',                label: 'Project',           link_to_facet: true
    config.add_show_field 'source_id_ssim',                  label: 'Source'
    config.add_show_field 'identifier_tesim',                label: 'IDs', helper_method: :value_for_identifier_tesim
    config.add_show_field 'originInfo_date_created_tesim',   label: 'Created'
    config.add_show_field 'preserved_size_dbtsi',            label: 'Preservation Size', helper_method: :preserved_size_human
    config.add_show_field 'tag_ssim',                        label: 'Tags',              link_to_facet: true
    config.add_show_field SolrDocument::FIELD_RELEASED_TO,   label: 'Released to'
    config.add_show_field 'status_ssi',                      label: 'Status'
    config.add_show_field 'wf_error_ssim',                   label: 'Error', helper_method: :value_for_wf_error
    config.add_show_field 'rights_descriptions_ssim',        label: 'Access Rights'

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim',                 label: 'Tag',                 limit: 9999,
                                                                component: LazyTagFacetComponent,
                                                                unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    config.add_facet_field 'objectType_ssim',                   label: 'Object Type',         component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_TYPE,    label: 'Content Type',        component: true, limit: 10
    config.add_facet_field 'content_file_mimetypes_ssim',       label: 'MIME Types',          component: true, limit: 10, home: false
    config.add_facet_field 'content_file_roles_ssim',           label: 'File Role',           component: true, limit: 10, home: false
    config.add_facet_field 'rights_descriptions_ssim',          label: 'Access Rights',       component: true, limit: 1000, sort: 'index', home: false
    config.add_facet_field 'use_license_machine_ssi',           label: 'License',             component: true, limit: 10, home: false
    config.add_facet_field 'nonhydrus_collection_title_ssim',   label: 'Collection',          component: true, limit: 10, more_limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_collection_title_ssim',      label: 'Hydrus Collection',   component: true, limit: 10, more_limit: 9999, sort: 'index', home: false
    config.add_facet_field 'nonhydrus_apo_title_ssim',          label: 'Admin Policy',        component: true, limit: 10, more_limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_apo_title_ssim',             label: 'Hydrus Admin Policy', component: true, limit: 10, more_limit: 9999, sort: 'index', home: false
    config.add_facet_field SolrDocument::FIELD_CURRENT_VERSION, label: 'Version',             component: true, limit: 10, home: false
    config.add_facet_field 'processing_status_text_ssi',        label: 'Processing Status',   component: true, limit: 10, home: false
    config.add_facet_field SolrDocument::FIELD_RELEASED_TO,     label: 'Released To',         component: true, limit: 10
    config.add_facet_field 'wf_wps_ssim',    label: 'Workflows (WPS)',
                                             component: Blacklight::Hierarchy::FacetFieldListComponent,
                                             limit: 9999
    config.add_facet_field 'wf_wsp_ssim',    label: 'Workflows (WSP)',
                                             component: Blacklight::Hierarchy::FacetFieldListComponent,
                                             limit: 9999,
                                             home: false
    config.add_facet_field 'wf_swp_ssim',    label: 'Workflows (SWP)',
                                             component: Blacklight::Hierarchy::FacetFieldListComponent,
                                             limit: 9999,
                                             home: false
    config.add_facet_field 'has_model_ssim', label: 'Object Model',
                                             component: true,
                                             limit: 10,
                                             home: false

    ## This is the costlier way to do this.  Instead convert this logic to delivering new values to a new field.  Then use normal add_facet_field.
    ## For now, if you add an additional case, make sure the DOR case gets the negation.
    config.add_facet_field 'source', label: 'Object Source', home: false,
                                     component: true,
                                     query: {
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

    config.add_facet_field 'metadata_source_ssi', label: 'Metadata Source', home: false,
                                                  component: true

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    # This will help us find records that need to be fixed before we can move to cocina.
    config.add_facet_field 'data_quality_ssim', label: 'Data Quality', home: false, component: true

    config.add_facet_field 'empties', label: 'Empty Fields', home: false,
                                      component: true,
                                      query: {
                                        no_source_id: { label: 'No Source ID', fq: '-source_id_ssim:*' },
                                        no_rights_characteristics: { label: 'No Rights Characteristics', fq: '-rights_characteristics_ssim:*' },
                                        no_content_type: { label: 'No Content Type', fq: '-content_type_ssim:*' },
                                        no_has_model: { label: 'No Object Model', fq: '-has_model_ssim:*' },
                                        no_objectType: { label: 'No Object Type', fq: "-#{SolrDocument::FIELD_OBJECT_TYPE}:*" },
                                        no_object_title: { label: 'No Object Title', fq: "-#{SolrDocument::FIELD_TITLE}:*" },
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

    config.add_facet_field 'sw_format_ssim',             label: 'SW Resource Type',     component: true, limit: 10, home: false
    config.add_facet_field 'sw_pub_date_facet_ssi',      label: 'SW Date',              component: true, limit: 10, home: false
    config.add_facet_field 'topic_ssim',                 label: 'SW Topic',             component: true, limit: 10, home: false
    config.add_facet_field 'sw_subject_geographic_ssim', label: 'SW Region',            component: true, limit: 10, home: false
    config.add_facet_field 'sw_subject_temporal_ssim',   label: 'SW Era',               component: true, limit: 10, home: false
    config.add_facet_field 'sw_genre_ssim',              label: 'SW Genre',             component: true, limit: 10, home: false
    config.add_facet_field 'sw_language_ssim',           label: 'SW Language',          component: true, limit: 10, home: false
    config.add_facet_field 'mods_typeOfResource_ssim',   label: 'MODS Resource Type',   component: true, limit: 10, home: false
    # Adding the facet field allows it to be queried (e.g., from value_helper)
    config.add_facet_field 'is_governed_by_ssim', if: false
    config.add_facet_field 'is_member_of_collection_ssim', if: false
    config.add_facet_field 'tag_ssim', if: false
    config.add_facet_field 'project_tag_ssim', if: false

    config.add_facet_fields_to_solr_request! # deprecated in newer Blacklights

    config.add_search_field 'text', label: 'All Fields'
    config.add_sort_field 'id asc', label: 'Druid'
    config.add_sort_field 'score desc', label: 'Relevance'

    config.spell_max = 5

    config.facet_display = {
      hierarchy: {
        'wf_wps' => [['ssim'], ':'],
        'wf_wsp' => [['ssim'], ':'],
        'wf_swp' => [['ssim'], ':'],
        'exploded_tag' => [['ssim'], ':']
      }
    }

    config.add_results_collection_tool(:bulk_update_view_button)
    config.add_results_collection_tool(:bulk_action_button)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    # config.add_results_collection_tool(:view_type_group)
    config.add_results_collection_tool(:report_view_toggle)

    ##
    # Configure document actions framework
    config.index.document_actions.delete(:bookmark)

    config.show.partials = %w[show_header full_view_links show_thumbnail show datastreams events cocina history contents techmd]
  end

  def index
    @presenter = HomeTextPresenter.new(current_user)
    super
  end

  def lazy_tag_facet
    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field('exploded_tag_ssim')
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_tag_facet'
  end

  def show
    params[:id] = 'druid:' + params[:id] unless params[:id].include? 'druid'
    _deprecated_response, @document = search_service.fetch(params[:id])

    @cocina = maybe_load_cocina(params[:id])
    flash[:alert] = 'Warning: this object cannot currently be represented in the Cocina model.' if @cocina.instance_of?(NilModel)

    authorize! :view_metadata, @cocina

    object_client = Dor::Services::Client.object(params[:id])
    @events = object_client.events.list

    @workflows = WorkflowService.workflows_for(druid: params[:id])

    milestones = MilestoneService.milestones_for(druid: params[:id])
    @milestones_presenter = MilestonesPresenter.new(milestones: milestones,
                                                    versions: object_client.version.inventory)

    @datastreams = object_client.metadata.datastreams
    @techmd = TechmdService.techmd_for(druid: params[:id])

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  private

  def limit_facets_on_home_page
    return if has_search_parameters? || params[:all]

    blacklight_config.facet_fields.each do |_k, v|
      v.include_in_request = false if v.home == false
    end
  end

  # do not add the pids_only search param to the blacklight search history (used in bulk actions only)
  def blacklisted_search_session_params
    super << :pids_only
  end

  # This overrides Blacklight to pass context to the search service
  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    { current_user: current_user }
  end
end
# rubocop:enable Metrics/ClassLength
