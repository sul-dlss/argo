# frozen_string_literal: true

# Handle editing the serials properties
class SerialsController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: "Repository", id_param: "item_id"

  def edit
    @form = SerialsForm.new(@cocina)
  end

  def update
    form = SerialsForm.new(@cocina)
    form.validate(params[:serials])
    form.save
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)

    msg = "Serials metadata has been updated!"
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg
  end
end
