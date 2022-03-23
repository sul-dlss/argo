# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ItemsController < ApplicationController
  before_action :load_resource
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
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    message = "Unable to retrieve the cocina model: #{detail.truncate(200)}"
    Honeybadger.notify(exception)
    logger.error "Error connecting to DSA: #{detail}"
    if turbo_frame_request?
      render 'error', locals: { message: message }
    else
      redirect_to solr_document_path(params[:id]),
                  flash: { error: message }
    end
  end

  rescue_from Cocina::Models::ValidationError, Repository::NotCocina do |exception|
    message = exception.is_a?(Repository::NotCocina) ? exception.message : "Error building Cocina: #{exception.message.truncate(200)}"
    Honeybadger.notify(exception)
    logger.error(message)
    if turbo_frame_request?
      render 'error', locals: { message: message }
    else
      redirect_to solr_document_path(params[:id]),
                  flash: { error: message }
    end
  end

  def add_collection
    response_message = if params[:collection].present?
                         new_collections = @item.collection_ids + [params[:collection]]
                         change_set = ItemChangeSet.new(@item)
                         change_set.validate(collection_ids: new_collections)
                         change_set.save
                         reindex
                         'Collection added successfully'
                       else
                         'No collection selected'
                       end

    object_client = Dor::Services::Client.object(@item.id)
    @collection_list = object_client.collections
    render partial: 'collection_ui', locals: { response_message: response_message }
  end

  def remove_collection
    new_collections = @item.collection_ids - [params[:collection]]
    change_set = ItemChangeSet.new(@item)
    change_set.validate(collection_ids: new_collections)
    change_set.save
    reindex

    object_client = Dor::Services::Client.object(@item.id)
    @collection_list = object_client.collections
    render partial: 'collection_ui', locals: { response_message: 'Collection successfully removed' }
  end

  def show
    authorize! :view_metadata, @item

    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @item.model).render }
    end
  end

  def source_id
    change_set = ItemChangeSet.new(@item)
    change_set.validate(source_id: params[:new_id])
    change_set.save
    reindex
    redirect_to solr_document_path(params[:id]), notice: "Source Id for #{params[:id]} has been updated!"
  end

  def purge_object
    if WorkflowService.submitted?(druid: params[:id])
      render status: :bad_request, plain: 'Cannot purge an object after it is submitted.'
      return
    end

    PurgeService.purge(druid: params[:id])

    redirect_to '/', status: :see_other, notice: "#{params[:id]} has been purged!"
  end

  def refresh_metadata
    authorize! :manage_desc_metadata, @item

    catkey = @item.catkey
    if catkey.blank?
      render status: :bad_request, plain: 'object must have catkey to refresh descMetadata'
      return
    end

    Dor::Services::Client.object(@item.id).refresh_metadata

    redirect_to solr_document_path(params[:id]), notice: "Metadata for #{@item.id} successfully refreshed from catkey: #{catkey}"
  rescue Dor::Services::Client::UnexpectedResponse => e
    user_begin = 'An error occurred while attempting to refresh metadata'
    user_end = 'Please try again or contact the #dlss-infrastructure Slack channel for assistance.'
    logger.error "#{user_begin}: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: "#{user_begin}: #{e.message}. #{user_end}" }
  end

  # set the object's access to its admin policy's accessTemplate
  def apply_apo_defaults
    Dor::Services::Client.object(@item.id).apply_admin_policy_defaults
    reindex
    redirect_to solr_document_path(params[:id]), notice: 'APO defaults applied!'
  rescue Dor::Services::Client::UnexpectedResponse => e
    error_message = "APO defaults could not be applied: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: error_message }
  end

  def set_governing_apo
    return redirect_to solr_document_path(params[:id]), flash: { error: "Can't set governing APO on an invalid model" } if @cocina.is_a? NilModel

    authorize! :manage_governing_apo, @item, params[:new_apo_id]

    change_set = build_change_set
    change_set.validate(admin_policy_id: params[:new_apo_id])
    change_set.save
    reindex

    redirect_to solr_document_path(params[:id]), notice: 'Governing APO updated!'
  end

  def collection_ui
    object_client = Dor::Services::Client.object(@item.id)
    @collection_list = object_client.collections
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # Draw form for barcode
  def edit_barcode
    @change_set = ItemChangeSet.new(@item)
  end

  def show_barcode
    change_set = ItemChangeSet.new(@item)
    state_service = StateService.new(@item)
    render Show::BarcodeComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for copyright
  def edit_copyright
    @change_set = build_change_set
  end

  def show_copyright
    change_set = build_change_set
    state_service = StateService.new(@item)
    render Show::CopyrightComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for use and reproduction statement
  def edit_use_statement
    @change_set = build_change_set
  end

  def show_use_statement
    change_set = build_change_set
    state_service = StateService.new(@item)
    render Show::UseStatementComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for setting license
  def edit_license
    @change_set = build_change_set
  end

  def show_license
    change_set = build_change_set
    state_service = StateService.new(@item)
    render Show::LicenseComponent.new(change_set: change_set, state_service: state_service)
  end

  # save the form
  def update
    change_set = ItemChangeSet.new(@item)
    if change_set.validate(**item_params)
      change_set.save # may raise Dor::Services::Client::BadRequestError
      reindex
      redirect_to solr_document_path(params[:id]), status: :see_other
    else
      message = change_set.errors.full_messages.to_sentence
      logger.error "Errors: #{message}"
      render 'error', locals: { message: message }
    end
  end

  def edit_rights
    @change_set = build_change_set
    if @item.is_a?(Collection)
      render partial: 'edit_collection_rights'
    else
      render partial: 'edit_dro_rights'
    end
  end

  def show_rights
    @change_set = build_change_set
    state_service = StateService.new(@item)
    if @item.is_a? Collection
      change_set = CollectionChangeSet.new(@item)
      render Show::Collection::AccessRightsComponent.new(change_set: change_set, state_service: state_service)
    else
      change_set = ItemChangeSet.new(@item)
      render Show::Item::AccessRightsComponent.new(change_set: change_set, state_service: state_service)
    end
  end

  def set_governing_apo_ui
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

  def load_resource
    @item = Repository.find(params[:id])
  end

  def reindex
    Argo::Indexer.reindex_druid_remotely(@item.id)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :manage_item, @item
  end

  def build_change_set
    change_set_class.new(@item)
  end

  def change_set_class
    case @item
    when Item
      ItemChangeSet
    when Collection
      CollectionChangeSet
    end
  end
end
# rubocop:enable Metrics/ClassLength
