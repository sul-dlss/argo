# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  before_action :load_and_authorize_cocina
  before_action :enforce_versioning, only: :update

  def show
    respond_to do |format|
      format.csv do
        filename = "structure-#{Druid.new(@cocina).without_namespace}.csv"
        send_data StructureSerializer.as_csv(@cocina.structural), filename: filename
      end
    end
  end

  def update
    authorize! :manage_item, @cocina

    status = StructureUpdater.from_csv(@cocina, params[:csv].read)

    if status.success?
      Repository.store(@cocina.new(structural: status.value!))
      redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: 'Structural metadata updated'
    else
      redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: status.failure.join('\n') }
    end
  end

  private

  def load_and_authorize_cocina
    @cocina = Repository.find(params[:item_id])
    authorize! :manage_item, @cocina
  end
end
