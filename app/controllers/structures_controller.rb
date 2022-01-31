# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  before_action :load_cocina

  def show
    authorize! :manage_item, @cocina

    respond_to do |format|
      format.csv do
        filename = "structure-#{@cocina.externalIdentifier.delete_prefix('druid:')}.csv"
        send_data StructureSerializer.as_csv(@cocina.structural), filename: filename
      end
    end
  end

  def update
    authorize! :manage_item, @cocina

    status = StructureUpdater.from_csv(@cocina, params[:csv].read)

    if status.success?
      object_client.update(params: @cocina.new(structural: status.value!))
      redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: 'Structural metadata updated'
    else
      redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: status.failure.join('\n') }
    end
  end

  private

  def load_cocina
    @cocina = object_client.find
  end

  def object_client
    @object_client ||= Dor::Services::Client.object(params[:item_id])
  end
end