# frozen_string_literal: true

# Manages HTTP interactions for creating collections
class CollectionsController < ApplicationController
  def new
    @cocina = Dor::Services::Client.object(params[:apo_id]).find
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def create
    cocina = Dor::Services::Client.object(params[:apo_id]).find
    authorize! :manage_item, cocina

    @apo = Dor.find params[:apo_id]
    form = CollectionForm.new(Dor::Collection.new)
    return render 'new' unless form.validate(params.merge(apo_pid: params[:apo_id]))

    form.save
    collection_pid = form.model.id
    @apo.add_default_collection collection_pid
    redirect_to solr_document_path(params[:apo_id]), notice: "Created collection #{collection_pid}"
    @apo.save # indexing happens automatically
  end

  def exists
    where_params = {}
    where_params[:title_ssi] = params[:title] if params[:title].present?
    where_params[:identifier_ssim] = "catkey:#{params[:catkey]}" if params[:catkey].present?
    resp = where_params.empty? ? false : Dor::Collection.where(where_params).any?
    render json: resp.to_json, layout: false
  end
end
