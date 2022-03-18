# frozen_string_literal: true

class CatkeysController < ApplicationController
  before_action :load_and_authorize_resource

  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    redirect_to solr_document_path(params[:item_id]),
                flash: { error: "Unable to retrieve the cocina model: #{detail.truncate(200)}" }
  end

  def edit
    @change_set = change_set_class.new(@cocina)
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    change_set = change_set_class.new(@cocina)
    change_set.validate(catkey: update_params[:catkey].strip)
    change_set.save
    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)

    msg = "Catkey for #{@cocina.externalIdentifier} has been updated!"
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg
  end

  private

  def change_set_class
    case @cocina
    when Cocina::Models::DRO, Cocina::Models::DROWithMetadata
      ItemChangeSet
    when Cocina::Models::Collection, Cocina::Models::CollectionWithMetadata
      CollectionChangeSet
    end
  end

  def load_and_authorize_resource
    @cocina = maybe_load_cocina(params[:item_id])
    authorize! :manage_item, @cocina
  end

  def update_params
    params[change_set_class.model_name.param_key]
  end
end
