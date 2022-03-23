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
        filename = "structure-#{Druid.new(@item.id).without_namespace}.csv"
        send_data StructureSerializer.as_csv(@item.structural), filename: filename
      end
      format.html do
        # Lazy loading of the structural part of the show page
        @item = Repository.find(decrypted_token.fetch(:key))
      end
    end
  end

  def update
    status = StructureUpdater.from_csv(@item, params[:csv].read)

    if status.success?
      Repository.store(@item.new(structural: status.value!))
      redirect_to solr_document_path(@item.id), status: :see_other, notice: 'Structural metadata updated'
    else
      redirect_to solr_document_path(@item.id), flash: { error: status.failure.join('\n') }
    end
  end

  private

  def load_and_authorize_resource
    @item = Repository.find(params[:item_id])
    authorize! :manage_item, @item
  end

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
