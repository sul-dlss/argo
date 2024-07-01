# frozen_string_literal: true

class CatalogController < ApplicationController
  include Blacklight::Catalog
  helper ArgoHelper
  include DateFacetConfigurations

  before_action :limit_facets_on_home_page, only: [:index]
  before_action :adjust_lazy_limits, only: [:index]

  # The subset of facets that are displayed on the home page.
  # (Before a user clicks "Show more facets")
  HOME_FACETS = [
    'exploded_project_tag_ssim',
    'exploded_nonproject_tag_ssim',
    'objectType_ssim',
    SolrDocument::FIELD_CONTENT_TYPE,
    SolrDocument::FIELD_COLLECTION_TITLE,
    'nonhydrus_apo_title_ssim',
    'released_to_earthworks',
    'released_to_searchworks',
    'wf_wps_ssim',
    'identifier_tesim'
  ].map(&:to_s).freeze

  # Facets that are configured for lazy loading.
  LAZY_FACETS = %w[
    exploded_project_tag_ssim
    exploded_nonproject_tag_ssim
    wf_wps_ssim
  ].map(&:to_s).freeze

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

    # exploded_project_tag_ssim indexes all project tag prefixes for hierarchical facet display, whereas
    #   project tag_ssim only indexes whole tags
    config.add_facet_field 'exploded_project_tag_ssim', label: 'Project', limit: 100_000,
                                                        component: LazyProjectTagFacetComponent,
                                                        unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    # exploded_nonproject_tag_ssim indexes all tag prefixes, except project tags, for hierarchical facet display,
    #   whereas tag_ssim only indexes whole tags.
    config.add_facet_field 'exploded_nonproject_tag_ssim', label: 'Tag', limit: 100_000,
                                                           component: LazyNonprojectTagFacetComponent,
                                                           unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    config.add_facet_field 'objectType_ssim', label: 'Object Type', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_TYPE, label: 'Content Type', component: true, limit: 10
    config.add_facet_field 'content_file_mimetypes_ssim', label: 'MIME Types', component: true, limit: 10
    config.add_facet_field 'content_file_roles_ssim', label: 'File Role', component: true, limit: 10
    config.add_facet_field 'rights_descriptions_ssim', label: 'Access Rights', component: true, limit: 1000,
                                                       sort: 'index'
    config.add_facet_field SolrDocument::FIELD_LICENSE, label: 'License', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection', component: true, limit: 10,
                                                                 more_limit: 9999, sort: 'index'
    config.add_facet_field 'nonhydrus_apo_title_ssim', label: 'Admin Policy', component: true, limit: 10,
                                                       more_limit: 9999, sort: 'index'
    config.add_facet_field SolrDocument::FIELD_CURRENT_VERSION, label: 'Version', component: true, limit: 10
    config.add_facet_field 'processing_status_text_ssi', label: 'Processing Status', component: true, limit: 10
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
    config.add_facet_field 'released_to_purl_sitemap',
                           component: true,
                           query: {
                             week: {
                               label: 'Last week',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_PURL_SITEMAP}:[NOW-7DAY/DAY TO NOW]"
                             },
                             month: {
                               label: 'Last month',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_PURL_SITEMAP}:[NOW-1MONTH/DAY TO NOW]"
                             },
                             year: {
                               label: 'Last year',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_PURL_SITEMAP}:[NOW-1YEAR/DAY TO NOW]"
                             },
                             ever: {
                               label: 'Currently released',
                               fq: "#{SolrDocument::FIELD_RELEASED_TO_PURL_SITEMAP}:[* TO *]"
                             },
                             never: {
                               label: 'Not released',
                               fq: "-#{SolrDocument::FIELD_RELEASED_TO_PURL_SITEMAP}:[* TO *]"
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
    config.add_facet_field 'wf_wps_ssim', label: 'Workflows (WPS)', limit: 9999,
                                          component: LazyWpsWorkflowFacetComponent
    config.add_facet_field 'wf_wsp_ssim', label: 'Workflows (WSP)',
                                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                                          limit: 9999
    config.add_facet_field 'wf_swp_ssim', label: 'Workflows (SWP)',
                                          component: Blacklight::Hierarchy::FacetFieldListComponent,
                                          limit: 9999

    config.add_facet_field 'metadata_source_ssim', label: 'Metadata Source', component: true

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    config.add_facet_field SolrDocument::FIELD_CONSTITUENTS, label: 'Virtual Objects', component: true,
                                                             query: {
                                                               has_constituents: { label: 'Virtual Objects', fq: "#{SolrDocument::FIELD_CONSTITUENTS}:*" }
                                                             }

    # This will help us find records that need to be fixed before we can move to cocina.
    config.add_facet_field 'data_quality_ssim', label: 'Data Quality', component: true

    config.add_facet_field 'identifiers', label: 'Identifiers',
                                          component: true,
                                          query: {
                                            has_orcids: { label: 'Has contributor ORCIDs',
                                                          fq: '+contributor_orcids_ssim:*' },
                                            has_doi: { label: 'Has DOI', fq: '+doi_ssim:*' },
                                            has_barcode: { label: 'Has barcode', fq: '+barcode_id_ssim:*' }
                                          }

    config.add_facet_field 'empties', label: 'Empty Fields', component: true,
                                      query: {
                                        no_mods_typeOfResource_ssim: { label: 'No MODS typeOfResource',
                                                                       fq: '-mods_typeOfResource_ssim:*' },
                                        no_sw_format: { label: 'No SW Resource Type', fq: '-sw_format_ssim:*' }
                                      }

    config.add_facet_field 'sw_format_ssim', label: 'SW Resource Type', component: true, limit: 10
    config.add_facet_field 'sw_pub_date_facet_ssi', label: 'SW Date', component: true, limit: 10
    config.add_facet_field 'topic_ssim', label: 'SW Topic', component: true, limit: 10
    config.add_facet_field 'sw_subject_geographic_ssim', label: 'SW Region', component: true, limit: 10
    config.add_facet_field 'sw_subject_temporal_ssim', label: 'SW Era', component: true, limit: 10
    config.add_facet_field 'sw_genre_ssim', label: 'SW Genre', component: true, limit: 10
    config.add_facet_field 'sw_language_ssim', label: 'SW Language', component: true, limit: 10
    config.add_facet_field 'mods_typeOfResource_ssim', label: 'MODS Resource Type', component: true, limit: 10
    # Adding the facet field allows it to be queried (e.g., from value_helper)
    config.add_facet_field 'is_governed_by_ssim', if: false
    config.add_facet_field 'is_member_of_collection_ssim', if: false
    config.add_facet_field 'tag_ssim', if: false
    config.add_facet_field 'project_tag_ssim', if: false

    config.add_facet_fields_to_solr_request! # deprecated in newer Blacklights

    config.add_search_field 'text', label: 'All Fields'
    config.add_sort_field 'score desc', label: 'Relevance', default: true
    config.add_sort_field 'id asc', label: 'Druid'

    config.spell_max = 5

    config.facet_display = {
      hierarchy: {
        'wf_wps' => [['ssim'], ':'],
        'wf_wsp' => [['ssim'], ':'],
        'wf_swp' => [['ssim'], ':'],
        'exploded_nonproject_tag' => [['ssim'], ':'],
        'exploded_project_tag' => [['ssim'], ':']
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
    # Request handlers can be configured:
    #  1. in Solr, in which case you can remove default_solr_params to use only
    #     what is in the Solr configuration.
    #  2. in Argo/Blacklight BUT the request handler (qt param) must match an existing request handler in Solr.
    #  3. configured with url params, e.g. qt=wingnut BUT - if default_solr_params are in play,
    #     you cannot override those params with url params, and the qt param value has to match an
    #     existing request handler in Solr.
    #  4. a combination of the above - some params can be configured in Solr, some in Argo/Blacklight, and some
    #     in the url.
    if params.key?(:qt)
      blacklight_config.default_solr_params = {
        qt: params[:qt],
        defType: 'dismax',
        'q.alt': '*:*',
        qf: %(
          main_title_text_anchored_im^100
          main_title_text_unstemmed_im^50
          main_title_tenim^10
          full_title_unstemmed_im^10
          full_title_tenim^5
          additional_titles_unstemmed_im^5
          additional_titles_tenim^3

          author_text_nostem_im^3
          contributor_text_nostem_im

          topic_tesim^2

          tag_text_unstemmed_im

          originInfo_place_placeTerm_tesim
          originInfo_publisher_tesim

          content_type_ssim
          sw_format_ssim
          object_type_ssim

          descriptive_text_nostem_i
          descriptive_tiv
          descriptive_teiv

          collection_title_tesim

          id
          druid_bare_ssi
          druid_prefixed_ssi
          obj_label_tesim
          identifier_ssim
          identifier_tesim
          barcode_id_ssim
          folio_instance_hrid_ssim
          source_id_text_nostem_i^3
          source_id_ssi
          previous_ils_ids_ssim
          doi_ssim
          contributor_orcids_ssim
        )
      }
      # NOTE: if you want to use the qf in solrconfig.xml, you can delete the qf param here:
      # blacklight_config.default_solr_params.delete(:qf) # use what is in solrconfig.xml for the request handler
    end
    super
  end

  def lazy_nonproject_tag_facet
    limit_facets_to(['exploded_nonproject_tag_ssim'])
    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field('exploded_nonproject_tag_ssim')
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_nonproject_tag_facet'
  end

  def lazy_project_tag_facet
    limit_facets_to(['exploded_project_tag_ssim'])

    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field('exploded_project_tag_ssim')
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_project_tag_facet'
  end

  def lazy_wps_workflow_facet
    limit_facets_to(['wf_wps_ssim'])

    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field('wf_wps_ssim')
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_wps_workflow_facet'
  end

  def show
    # If showing a user version, druid will be :item_id and user_version will be :id.
    @druid = Druid.new(params[:item_id] || params[:id]).with_namespace
    @user_version = params.key?(:item_id) ? params[:id] : nil
    _deprecated_response, @document = search_service.fetch(@druid)

    @cocina = Repository.find_lite(@druid, structural: false)
    if @cocina.instance_of?(NilModel)
      flash[:alert] =
        'Warning: this object cannot currently be represented in the Cocina model.'
    end

    authorize! :read, @cocina

    @workflows = WorkflowService.workflows_for(druid: @druid)

    @milestones_presenter = MilestonesPresenter.new(druid: @druid)
    raise ActionController::RoutingError, 'Not Found' unless @milestones_presenter.valid_user_version?(@user_version)

    @milestones_presenter = MilestonesPresenter.new(druid: @druid)
    @release_tags = @cocina.instance_of?(NilModel) || @cocina.admin_policy? ? [] : object_client.release_tags.list

    # If you have this token, it indicates you have read access to the object
    @verified_token_with_expiration = generate_token

    respond_to do |format|
      format.html { @search_context = setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  private

  def limit_facets_on_home_page
    return if has_search_parameters? || params[:all]

    limit_facets_to(HOME_FACETS)
  end

  # Removes facets that won't be displayed for faster querying.
  def limit_facets_to(fields)
    blacklight_config.facet_fields.each do |field, params|
      params.include_in_request = false unless fields.include?(field)
    end
  end

  # Lowers the limits for facets that are configured for lazy loading for faster querying.
  def adjust_lazy_limits
    blacklight_config.facet_fields.each do |field, params|
      params.limit = 1 if LAZY_FACETS.include?(field)
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

  def generate_token
    Argo.verifier.generate(
      { druid: @druid, user_version: @user_version },
      expires_in: 1.hour,
      purpose: :view_token
    )
  end

  def object_client
    @object_client ||= Dor::Services::Client.object(@druid)
  end
end
