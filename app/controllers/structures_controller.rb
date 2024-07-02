# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id', only: :update
  before_action :enforce_versioning, only: :update

  def show
    respond_to do |format|
      format.csv do
        # Download the structural spreadsheet
        cocina = fetch_cocina
        authorize! :update, cocina
        filename = "structure-#{Druid.new(cocina).without_namespace}.csv"
        send_data StructureSerializer.as_csv(cocina.externalIdentifier, cocina.structural), filename:
      end
      format.html do
        # Lazy loading of the structural part of the show page
        @cocina_item = fetch_cocina
      end
    end
  end

  def update
    csv = params[:csv].read.force_encoding('UTF-8')
    StructureUpdater.from_csv(@cocina, csv)
                    .bind { |structural| CocinaValidator.validate_and_save(@cocina, structural:) }
                    .either(
                      ->(_updated) { display_success('Structural metadata updated') },
                      ->(messages) { display_error(messages) }
                    )
  end

  def hierarchy
    @cocina_item = fetch_cocina
    @root_directory = FileHierarchyService.to_hierarchy(cocina_object: @cocina_item)
  end

  private

  def item_id
    decrypted_token&.fetch(:druid, nil) || params[:item_id]
  end

  def user_version_id
    decrypted_token&.fetch(:user_version_id, nil) || params[:user_version_id]
  end

  def display_success(message)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: message
  end

  def display_error(messages)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other,
                                                                flash: { error: messages.join(', ') }
  end

  # decode the token that grants view access
  def decrypted_token
    Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end

  def fetch_cocina
    return Repository.find(item_id) unless user_version_id

    Repository.find_user_version(item_id, user_version_id)
  end
end
