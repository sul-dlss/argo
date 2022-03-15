# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ItemsController < ApplicationController
  before_action :load_cocina
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
    source_id
    refresh_metadata
    set_rights
    set_governing_apo
    update
  ]

  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    message = "Unable to retrieve the cocina model: #{detail.truncate(200)}"
    logger.error "Error connecting to DSA: #{detail}"
    if turbo_frame_request?
      render 'error', locals: { message: message }
    else
      redirect_to solr_document_path(params[:id]),
                  flash: { error: message }
    end
  end

  rescue_from Cocina::Models::ValidationError do |exception|
    message = "Error building Cocina: #{exception.message.truncate(200)}"
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
                         new_collections = Array(@cocina.structural.isMemberOf) + [params[:collection]]
                         change_set = ItemChangeSet.new(@cocina)
                         change_set.validate(collection_ids: new_collections)
                         change_set.save
                         reindex
                         'Collection added successfully'
                       else
                         'No collection selected'
                       end

    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    @collection_list = object_client.collections
    render partial: 'collection_ui', locals: { response_message: response_message }
  end

  def remove_collection
    new_collections = Array(@cocina.structural.isMemberOf) - [params[:collection]]
    change_set = ItemChangeSet.new(@cocina)
    change_set.validate(collection_ids: new_collections)
    change_set.save
    reindex

    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    @collection_list = object_client.collections
    render partial: 'collection_ui', locals: { response_message: 'Collection successfully removed' }
  end

  def show
    authorize! :view_metadata, @cocina

    respond_to do |format|
      format.json { render json: @cocina }
    end
  end

  # Given two instances of VersionTag, find the most significant difference
  # between the two (return nil if either one is nil or if they're the same)
  # @param [String] cur_version_tag   current version tag
  # @param [String] prior_version_tag prior version tag
  # @return [Symbol] :major, :minor, :admin or nil
  def which_significance_changed(cur_version_tag, prior_version_tag)
    return nil if cur_version_tag.nil? || prior_version_tag.nil?
    return :major if cur_version_tag.major != prior_version_tag.major
    return :minor if cur_version_tag.minor != prior_version_tag.minor
    return :admin if cur_version_tag.admin != prior_version_tag.admin

    nil
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
      render status: :bad_request, plain: 'Cannot purge an object after it is submitted.'
      return
    end

    PurgeService.purge(druid: params[:id])

    redirect_to '/', status: :see_other, notice: "#{params[:id]} has been purged!"
  end

  def refresh_metadata
    authorize! :manage_desc_metadata, @cocina

    catkey = @cocina.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
    if catkey.blank?
      render status: :bad_request, plain: 'object must have catkey to refresh descMetadata'
      return
    end

    Dor::Services::Client.object(@cocina.externalIdentifier).refresh_metadata

    redirect_to solr_document_path(params[:id]), notice: "Metadata for #{@cocina.externalIdentifier} successfully refreshed from catkey: #{catkey}"
  rescue Dor::Services::Client::UnexpectedResponse => e
    user_begin = 'An error occurred while attempting to refresh metadata'
    user_end = 'Please try again or contact the #dlss-infrastructure Slack channel for assistance.'
    logger.error "#{user_begin}: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: "#{user_begin}: #{e.message}. #{user_end}" }
  end

  def set_rights
    # Item may be a Collection or a DRO
    form_type = @cocina.collection? ? CollectionRightsForm : DroRightsForm
    form = form_type.new(@cocina)
    form_key = form.model_name.param_key
    form.validate(params[form_key])
    form.save
    redirect_to solr_document_path(params[:id]), notice: 'Rights updated!'
  rescue ArgumentError
    render status: :bad_request, plain: 'Invalid new rights setting.'
  end

  # set the object's access to its admin policy's accessTemplate
  def apply_apo_defaults
    Dor::Services::Client.object(@cocina.externalIdentifier).apply_admin_policy_defaults
    reindex
    redirect_to solr_document_path(params[:id]), notice: 'APO defaults applied!'
  rescue Dor::Services::Client::UnexpectedResponse => e
    error_message = "APO defaults could not be applied: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: error_message }
  end

  def set_governing_apo
    return redirect_to solr_document_path(params[:id]), flash: { error: "Can't set governing APO on an invalid model" } if @cocina.is_a? NilModel

    authorize! :manage_governing_apo, @cocina, params[:new_apo_id]

    change_set = build_change_set
    change_set.validate(admin_policy_id: params[:new_apo_id])
    change_set.save
    reindex

    redirect_to solr_document_path(params[:id]), notice: 'Governing APO updated!'
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
    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)
    render Show::BarcodeComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for copyright
  def edit_copyright
    @change_set = build_change_set
  end

  def show_copyright
    change_set = ItemChangeSet.new(@cocina)
    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)
    render Show::CopyrightComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for use and reproduction statement
  def edit_use_statement
    @change_set = build_change_set
  end

  def show_use_statement
    change_set = ItemChangeSet.new(@cocina)
    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)
    render Show::UseStatementComponent.new(change_set: change_set, state_service: state_service)
  end

  # Draw form for setting license
  def edit_license
    @change_set = build_change_set
  end

  def show_license
    change_set = ItemChangeSet.new(@cocina)
    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)
    render Show::LicenseComponent.new(change_set: change_set, state_service: state_service)
  end

  # save the form
  def update
    change_set = ItemChangeSet.new(@cocina)
    attributes = params.require(:item).permit(:barcode, :copyright, :use_statement, :license)
    if change_set.validate(**attributes)
      change_set.save # may raise Dor::Services::Client::BadRequestError
      reindex
      redirect_to solr_document_path(params[:id]), status: :see_other
    else
      message = change_set.errors.full_messages.to_sentence
      logger.error "Errors: #{message}"
      render 'error', locals: { message: message }
    end
  end

  def rights
    return redirect_to solr_document_path(params[:id]), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    form_type = @cocina.collection? ? CollectionRightsForm : DroRightsForm
    cocina_admin_policy = Dor::Services::Client.object(@cocina.administrative.hasAdminPolicy).find

    default_rights = RightsLabeler.label(cocina_admin_policy.administrative.accessTemplate)
    @form = form_type.new(@cocina, default_rights: default_rights)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
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

  # NOTE: temporarily added to revert argo#2008; remove once argo#2007 is resolved
  def tags_client
    Dor::Services::Client.object(@cocina.externalIdentifier).administrative_tags
  end

  def load_cocina
    raise 'missing druid' unless params[:id]

    @cocina = maybe_load_cocina(params[:id])
  end

  def reindex
    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :manage_item, @cocina
  end

  def build_change_set
    @cocina.collection? ? CollectionChangeSet.new(@cocina) : ItemChangeSet.new(@cocina)
  end
end
# rubocop:enable Metrics/ClassLength
