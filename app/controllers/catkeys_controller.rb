# frozen_string_literal: true

class CatkeysController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    redirect_to solr_document_path(params[:item_id]),
                flash: { error: "Unable to retrieve the cocina model: #{detail.truncate(200)}" }
  end

  def edit
    @change_set = CatkeyForm.new(@cocina)
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    form = CatkeyForm.new(@cocina)
    form.validate(catkey: update_params[:catkey].strip)
    form.save
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)

    msg = "Catkey for #{@cocina.externalIdentifier} has been updated!"
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg
  end

  private

  def update_params
    params[CatkeyForm.model_name.param_key]
  end
end
