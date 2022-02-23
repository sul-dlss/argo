# frozen_string_literal: true

# Manages HTTP interactions for creating collections
class CollectionsController < ApplicationController
  include Blacklight::FacetsHelperBehavior # for facet_configuration_for_field

  def new
    @cocina = maybe_load_cocina(params[:apo_id])
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def create
    cocina = maybe_load_cocina(params[:apo_id])
    authorize! :manage_item, cocina

    form = CollectionForm.new
    return render 'new' unless form.validate(params.merge(apo_pid: params[:apo_id]))

    form.save
    collection_pid = form.model.externalIdentifier

    cocina_admin_policy = object_client.find
    collections = Array(cocina_admin_policy.administrative.collectionsForRegistration).dup
    # The following two steps mimic the behavior of `Dor::AdministrativeMetadataDS#add_default_collection` (from the now de-coupled dor-services gem)
    # 1. If collection is already listed, remove it temporarily
    collections.delete(collection_pid)
    # 2. Move the collection PID to the front of the list of registration collections
    collections.unshift(collection_pid)
    updated_cocina_admin_policy = cocina_admin_policy.new(
      administrative: cocina_admin_policy.administrative.new(
        collectionsForRegistration: collections
      )
    )
    object_client.update(params: updated_cocina_admin_policy)
    Argo::Indexer.reindex_pid_remotely(params[:apo_id])
    redirect_to solr_document_path(params[:apo_id]), notice: "Created collection #{collection_pid}"
  end

  # save the form
  def update
    @cocina = maybe_load_cocina(params[:id])
    authorize! :manage_item, @cocina

    attributes = params.require(:collection).permit(:copyright, :use_statement, :license, :project)

    # Editing project does not require versioning.
    return if attributes.except(:project).present? && !enforce_versioning

    change_set = CollectionChangeSet.new(@cocina)
    change_set.validate(**attributes)
    change_set.save
    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)

    redirect_to solr_document_path(params[:id]), status: :see_other
  end

  def exists
    resp = collection_exists?(title: params[:title].presence, catkey: params[:catkey].presence)
    render json: resp.to_json, layout: false
  end

  # render the count of collections
  def count
    query = "_query_:\"{!raw f=#{CollectionConcern::FIELD_COLLECTION_ID}}info:fedora/#{params[:id]}\""
    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })

    path_for_facet = link_to_collection

    render partial: 'count', locals: { count: result.dig('response', 'numFound'), path_for_facet: path_for_facet }
  end

  def search_action_path(*args)
    search_catalog_path(*args)
  end

  private

  def link_to_collection
    facet_config = facet_configuration_for_field(CollectionConcern::FIELD_COLLECTION_ID)
    search_state = Blacklight::SearchState.new({}, blacklight_config)
    Blacklight::FacetItemPresenter.new("info:fedora/#{params[:id]}",
                                       facet_config,
                                       self,
                                       CollectionConcern::FIELD_COLLECTION_ID, search_state).href
  end

  def collection_exists?(title:, catkey:)
    return false unless title || catkey

    query = "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\""
    query += " AND #{SolrDocument::FIELD_LABEL}:\"#{title}\"" if title
    query += " AND identifier_ssim:\"catkey:#{params[:catkey]}\"" if catkey

    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })
    result.dig('response', 'numFound').to_i.positive?
  end

  def solr_conn
    @solr_conn ||= blacklight_config.repository_class.new(blacklight_config).connection
  end

  def object_client
    Dor::Services::Client.object(params[:apo_id])
  end
end
