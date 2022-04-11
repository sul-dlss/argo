# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  before_action :load_and_authorize_resource, only: :update
  before_action :enforce_versioning, only: :update

  def show
    respond_to do |format|
      format.csv do
        # Download the structural spreadsheet
        load_and_authorize_resource
        filename = "structure-#{Druid.new(@cocina).without_namespace}.csv"
        send_data StructureSerializer.as_csv(@cocina.structural), filename: filename
      end
      format.html do
        # Lazy loading of the structural part of the show page
        @cocina_item = Repository.find(decrypted_token.fetch(:key))
      end
    end
  end

  def update
    status = StructureUpdater.from_csv(@cocina, params[:csv].read)

    if status.success?
      Repository.store(@cocina.new(structural: status.value!))
      redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: 'Structural metadata updated'
    else
      redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: status.failure.join('\n') }
    end
  end

  private

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
