# frozen_string_literal: true

class CatkeysController < ApplicationController
  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    redirect_to solr_document_path(params[:id]),
                flash: { error: "Unable to retrieve the cocina model: #{detail.truncate(200)}" }
  end

  def edit
    @cocina = maybe_load_cocina(params[:item_id])
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    @cocina = maybe_load_cocina(params[:item_id])
    authorize! :manage_item, @cocina
    return unless enforce_versioning

    change_set = ItemChangeSet.new(catkey: params[:new_catkey].strip)
    ItemChangeSetPersister.update(@cocina, change_set)
    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Updated catkey' }
      else
        msg = "Catkey for #{params[:id]} has been updated!"
        format.any { redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg }
      end
    end
  end
end
