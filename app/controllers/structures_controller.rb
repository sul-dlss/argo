# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: "Repository", id_param: "item_id", only: :update
  before_action :enforce_versioning, only: :update

  def show
    respond_to do |format|
      format.csv do
        # Download the structural spreadsheet
        cocina = Repository.find(params[:item_id])
        authorize! :update, cocina
        filename = "structure-#{Druid.new(cocina).without_namespace}.csv"
        send_data StructureSerializer.as_csv(cocina.externalIdentifier, cocina.structural), filename:
      end
      format.html do
        # Lazy loading of the structural part of the show page
        @cocina_item = Repository.find(decrypted_token.fetch(:key))
      end
    end
  end

  def update
    StructureUpdater.from_csv(@cocina, params[:csv].read)
      .bind { |structural| CocinaValidator.validate_and_save(@cocina, structural:) }
      .either(
        ->(_updated) { display_success("Structural metadata updated") },
        ->(messages) { display_error(messages) }
      )
  end

  private

  def display_success(message)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: message
  end

  def display_error(messages)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, flash: {error: messages.join(", ")}
  end

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end
end
