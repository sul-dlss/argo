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
    SolrDocument::FIELD_EXPLODED_PROJECT_TAG,
    SolrDocument::FIELD_EXPLODED_NONPROJECT_TAG,
    SolrDocument::FIELD_TICKET_TAG,
    'exclude_google_books',
    SolrDocument::FIELD_OBJECT_TYPE,
    SolrDocument::FIELD_CONTENT_TYPE,
    SolrDocument::FIELD_COLLECTION_TITLE,
    SolrDocument::FIELD_APO_TITLE,
    'released_to_earthworks',
    'released_to_searchworks',
    SolrDocument::FIELD_WORKFLOW_WPS,
    'identifier_tesim'
  ].map(&:to_s).freeze

  # Facets that are configured for lazy loading.
  LAZY_FACETS = [
    SolrDocument::FIELD_EXPLODED_PROJECT_TAG,
    SolrDocument::FIELD_EXPLODED_NONPROJECT_TAG,
    SolrDocument::FIELD_WORKFLOW_WPS
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

    config.show.display_type_field = SolrDocument::FIELD_OBJECT_TYPE
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
    config.add_index_field SolrDocument::FIELD_TICKET_TAG, label: 'Ticket', link_to_facet: true

    config.add_index_field 'status_ssi', label: 'Status'
    config.add_index_field SolrDocument::FIELD_WORKFLOW_ERRORS, label: 'Error', helper_method: :value_for_wf_error
    config.add_index_field SolrDocument::FIELD_ACCESS_RIGHTS, label: 'Access Rights'

    config.add_show_field 'project_tag_ssim', label: 'Project', link_to_facet: true
    config.add_show_field SolrDocument::FIELD_TICKET_TAG, label: 'Ticket', link_to_facet: true
    config.add_show_field 'tag_ssim', label: 'Tags', link_to_facet: true
    config.add_show_field SolrDocument::FIELD_WORKFLOW_ERRORS, label: 'Error', helper_method: :value_for_wf_error

    # exploded_project_tag_ssimdv indexes all project tag prefixes for hierarchical facet display, whereas
    #   project tag_ssim only indexes whole tags
    config.add_facet_field SolrDocument::FIELD_EXPLODED_PROJECT_TAG, label: 'Project', limit: 100_000,
                                                                     component: LazyProjectTagFacetComponent,
                                                                     unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    # exploded_nonproject_tag_ssimdv indexes all tag prefixes, except project tags, for hierarchical facet display,
    #   whereas tag_ssim only indexes whole tags.
    config.add_facet_field SolrDocument::FIELD_EXPLODED_NONPROJECT_TAG, label: 'Tag', limit: 100_000,
                                                                        component: LazyNonprojectTagFacetComponent,
                                                                        unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    config.add_facet_field SolrDocument::FIELD_TICKET_TAG, label: 'Ticket', component: true, limit: 100_000, sort: 'index',
                                                           unless: ->(controller, _config, _response) { controller.params[:no_tags] }
    config.add_facet_field 'exclude_google_books', label: 'Exclude Google Books', component: true, query: {
      yes: {
        label: 'Yes',
        fq: "-#{SolrDocument::FIELD_APO_ID}:\"#{Settings.google_books_apo}\""
      }
    }
    config.add_facet_field SolrDocument::FIELD_OBJECT_TYPE, label: 'Object Type', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_TYPE, label: 'Content Type', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_FILE_MIMETYPES, label: 'MIME Types', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_CONTENT_FILE_ROLES, label: 'File Role', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_ACCESS_RIGHTS, label: 'Access Rights', component: true, limit: 1000,
                                                              sort: 'index'
    config.add_facet_field SolrDocument::FIELD_LICENSE, label: 'License', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection', component: true, limit: 10,
                                                                 more_limit: 9999, sort: 'index'
    config.add_facet_field SolrDocument::FIELD_APO_TITLE, label: 'Admin Policy', component: true, limit: 10,
                                                          more_limit: 9999, sort: 'index'
    config.add_facet_field SolrDocument::FIELD_CURRENT_VERSION, label: 'Version', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_PROCESSING_STATUS, label: 'Processing Status', component: true, limit: 10
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
    config.add_facet_field SolrDocument::FIELD_WORKFLOW_WPS, label: 'Workflows (WPS)', limit: 9999,
                                                             component: LazyWpsWorkflowFacetComponent
    config.add_facet_field SolrDocument::FIELD_WORKFLOW_WSP, label: 'Workflows (WSP)',
                                                             component: Blacklight::Hierarchy::FacetFieldListComponent,
                                                             limit: 9999
    config.add_facet_field SolrDocument::FIELD_WORKFLOW_SWP, label: 'Workflows (SWP)',
                                                             component: Blacklight::Hierarchy::FacetFieldListComponent,
                                                             limit: 9999

    config.add_facet_field SolrDocument::FIELD_METADATA_SOURCE, label: 'Metadata Source', component: true

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    config.add_facet_field 'identifiers', label: 'Identifiers',
                                          component: true,
                                          query: {
                                            has_orcids: { label: 'Has contributor ORCIDs',
                                                          fq: "+#{SolrDocument::FIELD_ORCIDS}:*" },
                                            has_doi: { label: 'Has DOI', fq: "+#{SolrDocument::FIELD_DOI}:*" },
                                            has_barcode: { label: 'Has barcode', fq: "+#{SolrDocument::FIELD_BARCODE_ID}:*" }
                                          }

    config.add_facet_field 'empties', label: 'Empty Fields', component: true,
                                      query: {
                                        no_mods_typeOfResource_ssim: { label: 'No MODS typeOfResource',
                                                                       fq: "-#{SolrDocument::FIELD_MODS_TYPE_OF_RESOURCE}:*" },
                                        no_sw_format: { label: 'No SW Resource Type', fq: "-#{SolrDocument::FIELD_SW_FORMAT}:*" }
                                      }

    config.add_facet_field SolrDocument::FIELD_SW_FORMAT, label: 'SW Resource Type', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_PUBLICATION_DATE, label: 'Date', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_TOPIC, label: 'Topic', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_SUBJECT_GEOGRAPHIC, label: 'Region', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_SUBJECT_TEMPORAL, label: 'Era', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_GENRE, label: 'Genre', component: true, limit: 10
    config.add_facet_field SolrDocument::FIELD_SW_LANGUAGE, label: 'Language', component: true, limit: 10

    config.add_facet_field SolrDocument::FIELD_MODS_TYPE_OF_RESOURCE, label: 'MODS Resource Type', component: true, limit: 10
    # Adding the facet field allows it to be queried (e.g., from value_helper)
    config.add_facet_field SolrDocument::FIELD_APO_ID, if: false
    config.add_facet_field SolrDocument::FIELD_COLLECTION_ID, if: false
    config.add_facet_field 'tag_ssim', if: false
    config.add_facet_field 'project_tag_ssim', if: false

    config.add_facet_fields_to_solr_request! # deprecated in newer Blacklights

    config.add_search_field 'text', label: 'All Fields'
    config.add_sort_field 'score desc, id asc', label: 'Relevance', default: true
    config.add_sort_field 'id asc', label: 'Druid'

    config.spell_max = 5

    config.facet_display = {
      hierarchy: {
        'wf_wps' => [['ssimdv'], ':'],
        'wf_wsp' => [['ssimdv'], ':'],
        'wf_swp' => [['ssimdv'], ':'],
        'exploded_nonproject_tag' => [['ssimdv'], ':'],
        'exploded_project_tag' => [['ssimdv'], ':']
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

          subject_topic_tesim^2

          tag_text_unstemmed_im

          originInfo_place_placeTerm_tesim
          originInfo_publisher_tesim

          content_type_ssimdv
          sw_resource_type_ssimdv
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
          barcode_id_ssimdv
          folio_instance_hrid_ssim
          source_id_text_nostem_i^3
          source_id_ssi
          previous_ils_ids_ssim
          doi_ssimdv
          contributor_orcids_ssimdv
        )
      }
      # NOTE: if you want to use the qf in solrconfig.xml, you can delete the qf param here:
      # blacklight_config.default_solr_params.delete(:qf) # use what is in solrconfig.xml for the request handler
    end
    super
  end

  def lazy_nonproject_tag_facet
    limit_facets_to([SolrDocument::FIELD_EXPLODED_NONPROJECT_TAG])
    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field(SolrDocument::FIELD_EXPLODED_NONPROJECT_TAG)
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_nonproject_tag_facet'
  end

  def lazy_project_tag_facet
    limit_facets_to([SolrDocument::FIELD_EXPLODED_PROJECT_TAG])
    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field(SolrDocument::FIELD_EXPLODED_PROJECT_TAG)
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_project_tag_facet'
  end

  def lazy_wps_workflow_facet
    limit_facets_to([SolrDocument::FIELD_WORKFLOW_WPS])

    (response,) = search_service.search_results
    facet_config = facet_configuration_for_field(SolrDocument::FIELD_WORKFLOW_WPS)
    display_facet = response.aggregations[facet_config.field]
    @facet_field_presenter = facet_config.presenter.new(facet_config, display_facet, view_context)
    render partial: 'lazy_wps_workflow_facet'
  end

  def show
    if user_version_param
      @cocina = Repository.find_user_version(druid_param, user_version_param)
      @document = SolrDocument.new(object_client.user_version.solr(user_version_param))
    elsif version_param
      @cocina = Repository.find_version(druid_param, version_param)
      @document = SolrDocument.new(object_client.version.solr(version_param))
    else
      _deprecated_response, @document = search_service.fetch(druid_param)
      @cocina = Repository.find_lite(druid_param, structural: false)
    end

    authorize! :read, @cocina

    @workflows = WorkflowService.workflows_for(druid: druid_param)

    @user_versions_presenter = UserVersionsPresenter.new(user_version_view: user_version_param, user_version_inventory: object_client.user_version.inventory)
    @versions_presenter = VersionsPresenter.new(version_view: version_param, version_inventory:)
    @milestones_presenter = MilestonesPresenter.new(druid: druid_param, version_inventory:)

    @head_user_version = @user_versions_presenter.head_user_version
    @release_tags = @cocina.admin_policy? ? [] : object_client.release_tags.list

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
      { druid: druid_param, user_version_id: user_version_param, version_id: version_param },
      expires_in: 12.hours,
      purpose: :view_token
    )
  end

  def object_client
    @object_client ||= Dor::Services::Client.object(druid_param)
  end

  def version_inventory
    @version_inventory ||= object_client.version.inventory
  end

  def user_version_param
    @user_version_param ||= params[:user_version_id]
  end

  def version_param
    @version_param ||= params[:version_id]
  end

  def druid_param
    @druid_param ||= Druid.new(params[:item_id] || params[:id]).with_namespace
  end
end
