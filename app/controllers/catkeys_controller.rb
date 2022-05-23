# frozen_string_literal: true

class CatkeysController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  def edit
    @form = CatkeyForm.new(@cocina)
    @form.prepopulate!
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    @form = CatkeyForm.new(@cocina)
    if @form.validate(params[:catkey]) && @form.save
      Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)
      msg = "Catkeys for #{@cocina.externalIdentifier} have been updated!"
      redirect_to solr_document_path(@cocina.externalIdentifier, format: :html), notice: msg
    else
      render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_entity
    end
  end
end
