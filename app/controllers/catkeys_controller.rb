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

  def load_and_authorize_resource
    @cocina = Repository.find(params[:item_id])
    authorize! :update, @cocina
  end

  def update_params
    params[CatkeyForm.model_name.param_key]
  end
end
