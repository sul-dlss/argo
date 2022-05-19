# frozen_string_literal: true

class CatkeysController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  def edit
    @form = catkey_form
    @form.prepopulate!
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    @form = catkey_form
    if @form.validate(params[:catkey]) && @form.save(@cocina)
      Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)
      msg = "Catkeys for #{@cocina.externalIdentifier} have been updated!"
      redirect_to solr_document_path(@cocina.externalIdentifier, format: :html), notice: msg
    else
      render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_entity
    end
  end

  private

  def catkey_form
    # fetch catkeys from object
    object_catkeys = @cocina.identification.catalogLinks.filter_map { |catalog_link| catalog_link if catalog_link.catalog == Constants::SYMPHONY }

    # form is initialized with catkeys in the object
    catkeys = object_catkeys.map { |catkey| CatkeyForm::Row.new(value: catkey.catalogRecordId, refresh: catkey.refresh) }
    CatkeyForm.new(
      CatkeyForm::ModelProxy.new(
        id: params[:item_id],
        catkeys:
      )
    )
  end
end
