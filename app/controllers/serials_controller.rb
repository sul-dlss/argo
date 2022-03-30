# frozen_string_literal: true

# Handle editing the serials properties
class SerialsController < ApplicationController
  before_action :load_and_authorize_resource

  def edit
    @form = SerialsForm.new(@cocina)
  end

  def update
    form = SerialsForm.new(@cocina)
    form.validate(params[:serials])
    form.save
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)

    msg = 'Serials metadata has been updated!'
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: msg
  end

  private

  def load_and_authorize_resource
    @cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, @cocina
  end
end
