# frozen_string_literal: true

class CatalogController < ApplicationController
  include Blacklight::Catalog
  helper ArgoHelper
  include DateFacetConfigurations

  before_action :limit_facets_on_home_page, only: [:index]

  # NOTE: any Solr parameters configured here will override parameters in the Solr configuration files.
  configure_blacklight do |config|
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder

    # this helps get around issues with a large URL being sent to solr over GET, e.g. see https://github.com/sul-dlss/argo/issues/321 and
    #  https://github.com/projectblacklight/blacklight/issues/1324 and more recent issues in Aug 2021 with large solr queries being sent over GET
    config.http_method = :post

    # Configure the SearchState to know that "druids_only", is part of the state we care about.
    config.search_state_fields << :druids_only

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
    config.show.html_title_field = SolrDocument::FIELD_TITLE

    config.index.thumbnail_method = :render_thumbnail_helper

    config.add_index_field 'id', label: 'DRUID'
    config.add_index_field SolrDocument::FIELD_OBJECT_TYPE, label: 'Object Type'
    config.add_index_field SolrDocument::FIELD_CONTENT_TYPE, label: 'Content Type'
    config.add_index_field SolrDocument::FIELD_APO_ID, label: 'Admin Policy', helper_method: :link_to_admin_policy
    config.add_index_field SolrDocument::FIELD_COLLECTION_ID, label: 'Collection', helper_method: :links_to_collections
    config.add_index_field SolrDocument::FIELD_PROJECT_TAG, label: 'Project', link_to_facet: true
    config.add_index_field SolrDocument::FIELD_SOURCE_ID, label: 'Source'
    config.add_index_field 'identifier_tesim', label: 'IDs', helper_method: :value_for_identifier_tesim
    config.add_index_field SolrDocument::FIELD_RELEASED_TO, label: 'Released to'

    config.add_index_field 'status_ssi', label: 'Status'
    config.add_index_field SolrDocument::FIELD_WORKFLOW_ERRORS, label: 'Error', helper_method: :value_for_wf_error
    config.add_index_field 'rights_descriptions_ssim', label: 'Access Rights'

    config.add_show_field 'project_tag_ssim', label: 'Project', link_to_facet: true
    config.add_show_field 'tag_ssim', label: 'Tags', link_to_facet: true
    config.add_show_field SolrDocument::FIELD_WORKFLOW_ERRORS, label: 'Error', helper_method: :value_for_wf_error

    # exploded_tag_ssim indexes all tag prefixes (see IdentityMetadataDS#to_solr for a more exact
    # description), whereas tag_ssim only indexes whole tags.  we want to facet on exploded_tag_ssim
    # to get the hierarchy.
    config.add_facet_field 'exploded_tag_ssim', label: 'Tag', limit: 9999,
                                                component: LazyTagFacetComponent,
                                                unless: lambda { |controller, _config, _response|
                                                          controller.params[:no_tags]
                                                        }
    config.add_facet_field 'objectType_ssim', label: 'Object Type', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_TYPE, label: 'Content Type', component: true, limit: 10
    config.add_facet_field 'content_file_mimetypes_ssim', label: 'MIME Types', component: true, limit: 10, home: false
    config.add_facet_field 'content_file_roles_ssim', label: 'File Role', component: true, limit: 10, home: false
    config.add_facet_field 'rights_descriptions_ssim', label: 'Access Rights', component: true, limit: 1000,
                                                       sort: 'index', home: false
    config.add_facet_field SolrDocument::FIELD_LICENSE, label: 'License', component: true, limit: 10, home: false
    config.add_facet_field SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection', component: true, limit: 10,
                                                                 more_limit: 9999, sort: 'index'
    config.add_facet_field 'nonhydrus_apo_title_ssim', label: 'Admin Policy', component: true, limit: 10,
                                                       more_limit: 9999, sort: 'index'
    config.add_facet_field 'hydrus_apo_title_ssim', label: 'Hydrus Admin Policy', component: true, limit: 10,
                                                    more_limit: 9999, sort: 'index', home: false
    config.add_facet_field SolrDocument::FIELD_CURRENT_VERSION, label: 'Version', component: true, limit: 10,
                                                                home: false
    config.add_facet_field 'processing_status_text_ssi', label: 'Processing Status', component: true, limit: 10,
                                                         home: false
    config.add_facet_field 'released_to_earthworks',
                           component: true,
                           query: {
                             week: {
                               label: 'Last week',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_EARTHWORKS}:[NOW-7DAY/DAY TO NOW]"
                             },
                             month: {
                               label: 'Last month',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_EARTHWORKS}:[NOW-1MONTH/DAY TO NOW]"
                             },
                             year: {
                               label: 'Last year',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_EARTHWORKS}:[NOW-1YEAR/DAY TO NOW]"
                             },
                             ever: {
                               label: 'Currently released',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_EARTHWORKS}:[* TO *]"
                             },
                             never: {
                               label: 'Not released',
                               fq: "-#{SolrDocument::FIELD_RELEASED_TO_EARTHWORKS}:[* TO *]"
                             }
                           }
    config.add_facet_field 'released_to_searchworks',
                           component: true,
                           query: {
                             week: {
                               label: 'Last week',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_SEARCHWORKS}:[NOW-7DAY/DAY TO NOW]"
                             },
                             month: {
                               label: 'Last month',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_SEARCHWORKS}:[NOW-1MONTH/DAY TO NOW]"
                             },
                             year: {
                               label: 'Last year',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_SEARCHWORKS}:[NOW-1YEAR/DAY TO NOW]"
                             },
                             ever: {
                               label: 'Currently released',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_SEARCHWORKS}:[* TO *]"
                             },
                             never: {
                               label: 'Not released',
                               fq: "-#{SolrDocument::FIELD_RELEASED_TO_SEARCHWORKS}:[* TO *]"
                             }
                           }
    config.add_facet_field 'wf_wps_ssim', label: 'Workflows (WPS)',
                                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                                          limit: 9999
    config.add_facet_field 'wf_wsp_ssim', label: 'Workflows (WSP)',
                                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                                          limit: 9999,
                                          home: false
    config.add_facet_field 'wf_swp_ssim', label: 'Workflows (SWP)',
                                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                                          limit: 9999,
                                          home: false

    config.add_facet_field 'metadata_source_ssim', label: 'Metadata Source', home: false,
                                                   component: true

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    config.add_facet_field SolrDocument::FIELD_CONSTITUENTS, label: 'Virtual Objects', home: false,
                                                             component: true,
                                                             query: {
                                                               has_constituents: { label: 'Virtual Objects', fq: "#{SolrDocument::FIELD_CONSTITUENTS}:*" }
                                                             }

    # This will help us find records that need to be fixed before we can move to cocina.
    config.add_facet_field 'data_quality_ssim', label: 'Data Quality', home: false, component: true

    config.add_facet_field 'identifiers', label: 'Identifiers',
                                          component: true,
                                          query: {
                                            has_orcids: { label: 'Has contributor ORCIDs',
                                                          fq: '+contributor_orcids_ssim:*' },
                                            has_doi: { label: 'Has DOI', fq: '+doi_ssim:*' },
                                            has_barcode: { label: 'Has barcode', fq: '+barcode_id_ssim:*' }
                                          }

    config.add_facet_field 'empties', label: 'Empty Fields', home: false,
                                      component: true,
                                      query: {
                                        no_mods_typeOfResource_ssim: { label: 'No MODS typeOfResource',
                                                                       fq: '-mods_typeOfResource_ssim:*' },
                                        no_sw_format: { label: 'No SW Resource Type', fq: '-sw_format_ssim:*' }
                                      }

    config.add_facet_field 'sw_format_ssim', label: 'SW Resource Type', component: true, limit: 10, home: false
    config.add_facet_field 'sw_pub_date_facet_ssi', label: 'SW Date', component: true, limit: 10, home: false
    config.add_facet_field 'topic_ssim', label: 'SW Topic', component: true, limit: 10, home: false
    config.add_facet_field 'sw_subject_geographic_ssim', label: 'SW Region', component: true, limit: 10, home: false
    config.add_facet_field 'sw_subject_temporal_ssim', label: 'SW Era', component: true, limit: 10, home: false
    config.add_facet_field 'sw_genre_ssim', label: 'SW Genre', component: true, limit: 10, home: false
    config.add_facet_field 'sw_language_ssim', label: 'SW Language', component: true, limit: 10, home: false
    config.add_facet_field 'mods_typeOfResource_ssim', label: 'MODS Resource Type', component: true, limit: 10,
                                                       home: false
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

    config.add_results_collection_tool(:bulk_action_button)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    # config.add_results_collection_tool(:view_type_group)
    config.add_results_collection_tool(:report_view_toggle)

    ##
    # Configure document actions framework
    config.index.document_actions.delete(:bookmark)

    config.show.document_component = DocumentComponent
  end

  def index
    @presenter = HomeTextPresenter.new(current_user)
    # For comparison of search results with different Solr params:
    # if qt param is passed to Argo, we can also change the params we send to Solr.
    # This allows us to compare, e.g. search results with different Solr qf params.
    # Request handlers can be wholly configured in Solr, in which case you can remove
    # default_solr_params to use what is in the Solr configuration.
    if params.key?(:qt)
      blacklight_config.default_solr_params = {
        qt: params[:qt],
        defType: 'dismax',
        'q.alt': '*:*',
        qf: %(
          id
          collection_title_tesim
          dor_id_tesim
          identifier_tesim
          obj_label_tesim
          objectId_tesim
          originInfo_place_placeTerm_tesim
          originInfo_publisher_tesim
          sw_display_title_tesim
          source_id_ssim
          tag_ssim
          topic_tesim
        )
      }
    end
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
    params[:id] = Druid.new(params[:id]).with_namespace
    _deprecated_response, @document = search_service.fetch(params[:id])

    @cocina = Repository.find_lite(params[:id], structural: false)
    if @cocina.instance_of?(NilModel)
      flash[:alert] =
        'Warning: this object cannot currently be represented in the Cocina model.'
    end

    authorize! :read, @cocina

    @workflows = WorkflowService.workflows_for(druid: params[:id])
    milestones = MilestoneService.milestones_for(druid: params[:id])
    object_client = Dor::Services::Client.object(params[:id])
    versions = object_client.version.inventory
    @milestones_presenter = MilestonesPresenter.new(milestones:, versions:)

    # If you have this token, it indicates you have read access to the object
    @verified_token_with_expiration = Argo.verifier.generate(
      { key: params[:id] },
      expires_in: 1.hour,
      purpose: :view_token
    )

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

  # do not add the druids_only search param to the blacklight search history (used in bulk actions only)
  def blacklisted_search_session_params
    super << :druids_only
  end

  # This overrides Blacklight to pass context to the search service
  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    { current_user: }
  end
end
