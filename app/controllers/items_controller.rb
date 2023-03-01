# frozen_string_literal: true

class ItemsController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: "Repository", only: :show

  before_action :load_cocina, except: :show
  before_action :authorize_manage!, only: %i[
    add_collection remove_collection
    purge_object
    show_barcode show_copyright show_license show_use_statement
    source_id
    update
  ]

  before_action :enforce_versioning, only: %i[
    add_collection remove_collection
    edit_copyright edit_license edit_use_statement
    edit_rights
    source_id
    refresh_metadata
    set_governing_apo
    update
  ]

  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    detail = exception.errors.first["detail"]&.truncate(1024) # Truncate to avoid cookie overflow. Cookies can hold 4k.
    message = "Unable to retrieve the cocina model: #{detail}"
    Honeybadger.notify(exception)
    logger.error "Error connecting to DSA: #{detail}"
    if turbo_frame_request?
      render "error", locals: {message:}
    else
      redirect_to solr_document_path(params[:id]),
        flash: {error: message}
    end
  end

  rescue_from Cocina::Models::ValidationError do |exception|
    message = "Error building Cocina: #{exception.message.truncate(200)}"
    Honeybadger.notify(exception)
    logger.error(message)
    if turbo_frame_request?
      render "error", locals: {message:}
    else
      redirect_to solr_document_path(params[:id]),
        flash: {error: message}
    end
  end

  def add_collection
    response_message = if params[:collection].present?
      new_collections = Array(@cocina.structural&.isMemberOf) + [params[:collection]]
      change_set = ItemChangeSet.new(@cocina)
      change_set.validate(collection_ids: new_collections)
      change_set.save
      reindex
      "Collection added successfully"
    else
      "No collection selected"
    end

    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    @collection_list = object_client.collections
    render partial: "collection_ui", locals: {response_message:}
  end

  def remove_collection
    new_collections = Array(@cocina.structural&.isMemberOf) - [params[:collection]]
    change_set = ItemChangeSet.new(@cocina)
    change_set.validate(collection_ids: new_collections)
    change_set.save
    reindex

    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    @collection_list = object_client.collections
    render partial: "collection_ui", locals: {response_message: "Collection successfully removed"}
  end

  def show
    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina).render }
    end
  end

  def source_id
    change_set = ItemChangeSet.new(@cocina)
    change_set.validate(source_id: params[:new_id])
    change_set.save
    reindex
    redirect_to solr_document_path(params[:id]), notice: "Source Id for #{params[:id]} has been updated!"
  end

  def purge_object
    if WorkflowService.submitted?(druid: params[:id])
      render status: :bad_request, plain: "Cannot purge an object after it is submitted."
      return
    end

    PurgeService.purge(druid: params[:id], user_name: current_user.login)

    redirect_to "/", status: :see_other, notice: "#{params[:id]} has been purged!"
  end

  def refresh_metadata
    authorize! :update, @cocina

    catalog_record_id = @cocina.identification&.catalogLinks&.find { |link| link.catalog == CatalogRecordId.type }&.catalogRecordId
    if catalog_record_id.blank?
      render status: :bad_request, plain: "object must have #{CatalogRecordId.label} to refresh descMetadata"
      return
    end

    Dor::Services::Client.object(@cocina.externalIdentifier).refresh_metadata

    redirect_to solr_document_path(params[:id]), notice: "Metadata for #{@cocina.externalIdentifier} successfully refreshed from #{CatalogRecordId.label}: #{catalog_record_id}"
  rescue Dor::Services::Client::UnexpectedResponse => e
    user_begin = "An error occurred while attempting to refresh metadata"
    user_end = "Please try again or contact the #dlss-infrastructure Slack channel for assistance."
    logger.error "#{user_begin}: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: {error: "#{user_begin}: #{e.message}. #{user_end}"}
  end

  # set the object's access to its admin policy's accessTemplate
  def apply_apo_defaults
    Dor::Services::Client.object(@cocina.externalIdentifier).apply_admin_policy_defaults
    reindex
    redirect_to solr_document_path(params[:id]), notice: "APO defaults applied!"
  rescue Dor::Services::Client::UnexpectedResponse => e
    error_message = "APO defaults could not be applied: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: {error: error_message}
  end

  def set_governing_apo
    return redirect_to solr_document_path(params[:id]), flash: {error: "Can't set governing APO on an invalid model"} if @cocina.is_a? NilModel

    authorize! :manage_governing_apo, @cocina, params[:new_apo_id]

    change_set = build_change_set
    change_set.validate(admin_policy_id: params[:new_apo_id])
    change_set.save
    reindex

    redirect_to solr_document_path(params[:id]), notice: "Governing APO updated!"
  end

  def collection_ui
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    @collection_list = object_client.collections
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # Draw form for barcode
  def edit_barcode
    @change_set = ItemChangeSet.new(@cocina)
  end

  def show_barcode
    change_set = ItemChangeSet.new(@cocina)
    state_service = StateService.new(@cocina)
    render Show::BarcodeComponent.new(change_set:, state_service:)
  end

  # Draw form for copyright
  def edit_copyright
    @change_set = build_change_set
  end

  def show_copyright
    change_set = build_change_set
    state_service = StateService.new(@cocina)
    render Show::CopyrightComponent.new(change_set:, state_service:)
  end

  # Draw form for use and reproduction statement
  def edit_use_statement
    @change_set = build_change_set
  end

  def show_use_statement
    change_set = build_change_set
    state_service = StateService.new(@cocina)
    render Show::UseStatementComponent.new(change_set:, state_service:)
  end

  # Draw form for setting license
  def edit_license
    @change_set = build_change_set
  end

  def show_license
    change_set = build_change_set
    state_service = StateService.new(@cocina)
    render Show::LicenseComponent.new(change_set:, state_service:)
  end

  # save the form
  def update
    change_set = ItemChangeSet.new(@cocina)
    if change_set.validate(**item_params)
      change_set.save # may raise Dor::Services::Client::BadRequestError
      reindex
      redirect_to solr_document_path(params[:id]), status: :see_other
    else
      render "error", locals: {message: change_set.errors.map(&:message).to_sentence}
    end
  end

  def edit_rights
    @change_set = build_change_set
    if @cocina.collection?
      render partial: "edit_collection_rights"
    else
      render partial: "edit_dro_rights"
    end
  end

  def show_rights
    @change_set = build_change_set
    state_service = StateService.new(@cocina)
    if @cocina.collection?
      change_set = CollectionChangeSet.new(@cocina)
      render Show::Collection::AccessRightsComponent.new(change_set:, state_service:)
    else
      change_set = ItemChangeSet.new(@cocina)
      render Show::Item::AccessRightsComponent.new(change_set:, state_service:)
    end
  end

  def set_governing_apo_ui
    @apo_list = AdminPolicyOptions.for(current_user)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def source_id_ui
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def item_params
    params.require(:item)
      .permit(:barcode, :copyright, :use_statement, :license,
        :view_access, :download_access, :access_location, :controlled_digital_lending)
  end

  def load_cocina
    raise "missing druid" unless params[:id]

    @cocina = Repository.find(params[:id])
  end

  def reindex
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :update, @cocina
  end

  def build_change_set
    @cocina.collection? ? CollectionChangeSet.new(@cocina) : ItemChangeSet.new(@cocina)
  end
end
