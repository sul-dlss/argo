# frozen_string_literal: true

class CatalogRecordIdsController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  def edit
    @form = CatalogRecordIdForm.new(@cocina)
    @form.prepopulate!
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    @form = CatalogRecordIdForm.new(@cocina)
    if @form.validate(params[:catalog_record_id]) && @form.save
      Dor::Services::Client.object(@cocina.externalIdentifier).reindex
      msg = "#{CatalogRecordId.label}s for #{@cocina.externalIdentifier} have been updated!"
      redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg
    else
      render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_content
    end
  end
end
