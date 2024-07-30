# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class StructuresController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id', only: :update
  before_action :enforce_versioning, only: :update

  def show
    respond_to do |format|
      format.csv do
        # Download the structural spreadsheet
        cocina = find_cocina(item_id: params[:item_id], user_version: params[:user_version], version: params[:version])
        authorize! :update, cocina
        filename = "structure-#{Druid.new(cocina).without_namespace}.csv"
        send_data StructureSerializer.as_csv(cocina.externalIdentifier, cocina.structural), filename:
      end
      format.html do
        # Lazy loading of the structural part of the show page
        @cocina_item = find_cocina_from_token
        @user_version = decrypted_token.fetch(:user_version_id, nil)
        @viewable = can?(:view_content, @cocina_item) && !params.key?(:version_id)
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
    @cocina_item = find_cocina_from_token
    @root_directory = FileHierarchyService.to_hierarchy(cocina_object: @cocina_item)
  end

  private

  def display_success(message)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: message
  end

  def display_error(messages)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other,
                                                                flash: { error: messages.join(', ') }
  end

  # decode the token that grants view access
  def decrypted_token
    @decrypted_token ||= Argo.verifier.verified(params[:item_id], purpose: :view_token)
  end

  def find_cocina_from_token
    find_cocina(item_id: decrypted_token.fetch(:druid),
                user_version: decrypted_token.fetch(:user_version_id, nil),
                version: decrypted_token.fetch(:version_id, nil))
  end

  def find_cocina(item_id:, user_version: nil, version: nil)
    if user_version
      Repository.find_user_version(item_id, user_version)
    elsif version
      Repository.find_version(item_id, version)
    else
      Repository.find(item_id)
    end
  end
end
