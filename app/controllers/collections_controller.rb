# frozen_string_literal: true

# Manages HTTP interactions for creating collections
class CollectionsController < ApplicationController
  include Blacklight::FacetsHelperBehavior # for facet_configuration_for_field

  def new
    authorize! :create, Cocina::Models::Collection

    if modal?
      @cocina_admin_policy = Repository.find(params[:apo_druid])
    else
      @apo_list = AdminPolicyOptions.for(current_user)
    end

    render new_view
  end

  def create
    @cocina_admin_policy = Repository.find(params[:apo_druid])
    authorize! :update, @cocina_admin_policy

    form = CollectionForm.new
    return render new_view unless form.validate(params)

    form.save
    collection_druid = form.model.externalIdentifier
    # open version for APO if not already open
    version_service = VersionService.new(druid: @cocina_admin_policy.externalIdentifier)
    @cocina_admin_policy = version_service.open(description: "Created new collection: #{collection_druid}") unless version_service.open?

    # update APO
    collections = Array(@cocina_admin_policy.administrative.collectionsForRegistration).dup
    # The following two steps mimic the behavior of `Dor::AdministrativeMetadataDS#add_default_collection` (from the now de-coupled dor-services gem)
    # 1. If collection is already listed, remove it temporarily
    collections.delete(collection_druid)
    # 2. Move the collection DRUID to the front of the list of registration collections
    collections.unshift(collection_druid)
    updated_cocina_admin_policy = @cocina_admin_policy.new(
      administrative: @cocina_admin_policy.administrative.new(
        collectionsForRegistration: collections
      )
    )
    Repository.store(updated_cocina_admin_policy)
    # Close the APO version
    version_service.close
    redirect_to solr_document_path(collection_druid), notice: "Created collection #{collection_druid}"
  end

  # save the form
  def update
    @cocina = Repository.find(params[:id])
    authorize! :update, @cocina
    return unless enforce_versioning?

    change_set = CollectionChangeSet.new(@cocina)
    attributes = params.expect(collection: %i[view_access copyright use_statement license])
    change_set.validate(**attributes)
    change_set.save
    Dor::Services::Client.object(@cocina.externalIdentifier).reindex

    redirect_to solr_document_path(params[:id]), status: :see_other
  end

  def exists
    resp = collection_exists?(title: params[:title].presence, catalog_record_id: params[:catalog_record_id].presence)
    render json: resp.to_json, layout: false
  end

  # render the count of collections
  def count
    query = "_query_:\"{!raw f=#{CollectionConcern::FIELD_COLLECTION_ID}}#{params[:id]}\""
    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })

    path_for_facet = link_to_collection

    render partial: 'count', locals: { count: result.dig('response', 'numFound'), path_for_facet: }
  end

  def search_action_path(*)
    search_catalog_path(*)
  end

  private

  def link_to_collection
    facet_config = facet_configuration_for_field(CollectionConcern::FIELD_COLLECTION_ID)
    search_state = Blacklight::SearchState.new({}, blacklight_config)
    Blacklight::FacetItemPresenter.new(params[:id],
                                       facet_config,
                                       self,
                                       CollectionConcern::FIELD_COLLECTION_ID, search_state).href
  end

  def collection_exists?(title:, catalog_record_id:)
    return false unless title || catalog_record_id

    query = "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\""
    query += " AND #{SolrDocument::FIELD_LABEL}:\"#{title}\"" if title
    if catalog_record_id
      query += " AND identifier_ssim:\"#{CatalogRecordId.indexing_prefix}:#{params[:catalog_record_id]}\""
    end

    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })
    result.dig('response', 'numFound').to_i.positive?
  end

  def solr_conn
    @solr_conn ||= blacklight_config.repository_class.new(blacklight_config).connection
  end

  def modal?
    params[:modal] == 'true'
  end

  def new_view
    modal? ? 'new_modal' : 'new'
  end
end
