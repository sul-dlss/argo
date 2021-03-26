# frozen_string_literal: true

# Manages HTTP interactions for creating collections
class CollectionsController < ApplicationController
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
    collections = Array(cocina_admin_policy.administrative.collectionsForRegistration)
    # The following two steps mimic the behavior of `Dor::AdministrativeMetadataDS#add_default_collection`
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

  def exists
    where_params = {}
    where_params[:title_ssi] = params[:title] if params[:title].present?
    where_params[:identifier_ssim] = "catkey:#{params[:catkey]}" if params[:catkey].present?
    resp = where_params.empty? ? false : Dor::Collection.where(where_params).any?
    render json: resp.to_json, layout: false
  end

  private

  def object_client
    Dor::Services::Client.object(params[:apo_id])
  end
end
