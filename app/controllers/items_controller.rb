# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ItemsController < ApplicationController
  include ModsDisplay::ControllerExtension
  before_action :load_cocina, except: :purl_preview
  before_action :create_obj, only: %i[apply_apo_defaults]

  before_action :authorize_manage!, only: %i[
    add_collection set_collection remove_collection
    mods
    purge_object
    source_id
    catkey
    tags_bulk
    embargo_update
    embargo_form
  ]

  before_action :enforce_versioning, only: %i[
    add_collection set_collection remove_collection
    source_id
    catkey
    refresh_metadata
    set_rights
    set_governing_apo
  ]

  rescue_from Dor::Services::Client::UnexpectedResponse do |exception|
    md = /\((.*)\)/.match exception.message
    detail = JSON.parse(md[1])['errors'].first['detail']
    redirect_to solr_document_path(params[:id]),
                flash: { error: "Unable to retrieve the cocina model: #{detail.truncate(200)}" }
  end

  def purl_preview
    xml = Dor::Services::Client.object(params[:id]).metadata.descriptive
    @mods_display = ModsDisplayObject.new(xml)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def embargo_form
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def set_collection
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    collection_id = params[:collection].presence
    updated_structural = if collection_id
                           @cocina.structural.new(isMemberOf: [collection_id])
                         else
                           @cocina.structural.to_h.without(:isMemberOf)
                         end
    updated = @cocina.new(structural: updated_structural)
    object_client.update(params: updated)
    reindex

    response_message = if params[:collection].present?
                         'Collection successfully set.'
                       else
                         'Collection(s) successfully removed.' # no collection selected from drop-down, so don't bother adding a new one
                       end

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: response_message }
      else
        format.html { redirect_to solr_document_path(params[:id]), notice: response_message }
      end
    end
  end

  def add_collection
    response_message = if params[:collection].present?
                         collection_id = params[:collection]
                         updated_structural = @cocina.structural.new(isMemberOf: @cocina.structural.isMemberOf + [collection_id])
                         updated = @cocina.new(structural: updated_structural)
                         object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
                         object_client.update(params: updated)

                         reindex
                         'Collection added successfully'
                       else
                         'No collection selected'
                       end
    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: response_message }
      else
        format.json do
          collection = Dor::Services::Client.object(params[:collection]).find
          new_collection_html = render_to_string('items/_collection_ui_line_item', formats: [:html], layout: false,
                                                                                   locals: {
                                                                                     collection_label: collection.label,
                                                                                     collection_id: collection.externalIdentifier,
                                                                                     item_id: @cocina.externalIdentifier
                                                                                   })
          render status: :ok, plain: { message: response_message, new_collection_html: new_collection_html }.to_json
        end
        format.html { redirect_to solr_document_path(params[:id]), notice: response_message }
      end
    end
  end

  def remove_collection
    collection_id = params[:collection]
    updated_structural = @cocina.structural.new(isMemberOf: @cocina.structural.isMemberOf - [collection_id])
    updated = @cocina.new(structural: updated_structural)
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    object_client.update(params: updated)
    reindex

    response_message = 'Collection successfully removed'
    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: response_message }
      else
        format.json { render status: :ok, plain: { message: response_message, druid: params[:collection].gsub('druid:', '') }.to_json }
        format.any  { redirect_to solr_document_path(params[:id]), notice: response_message }
      end
    end
  end

  def mods
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)

    respond_to do |format|
      format.xml  { render xml: object_client.metadata.mods }
    end
  end

  def embargo_update
    raise ArgumentError, 'Missing embargo_date parameter' unless params[:embargo_date].present?

    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    object_client.embargo.update(embargo_date: params[:embargo_date], requesting_user: current_user.to_s)

    reindex
    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: 'Embargo was successfully updated' }
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
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    updated_identification = @cocina.identification.new(sourceId: params[:new_id])
    updated = @cocina.new(identification: updated_identification)
    object_client.update(params: updated)
    reindex

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Updated source id.' }
      else
        msg = "Source Id for #{params[:id]} has been updated!"
        format.any { redirect_to solr_document_path(params[:id]), notice: msg }
      end
    end
  end

  def catkey
    object_client = Dor::Services::Client.object(params[:id])
    dro = object_client.find
    CatkeyService.update(dro, object_client, params[:new_catkey].strip)
    reindex

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Updated catkey' }
      else
        msg = "Catkey for #{params[:id]} has been updated!"
        format.any { redirect_to solr_document_path(params[:id]), notice: msg }
      end
    end
  end

  def tags_bulk
    tags = params[:tags].split(/\t/)
    # Destroy all current tags and replace with new ones
    tags_client.replace(tags: tags)
    reindex

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: "#{tags.size} Tags updated." }
      else
        msg = "#{tags.size} tags for #{params[:id]} have been updated!"
        format.any { redirect_to solr_document_path(params[:id]), notice: msg }
      end
    end
  end

  def purge_object
    if WorkflowService.submitted?(druid: params[:id])
      render status: :bad_request, plain: 'Cannot purge an object after it is submitted.'
      return
    end

    PurgeService.purge(druid: params[:id])

    redirect_to '/', notice: "#{params[:id]} has been purged!"
  end

  def refresh_metadata
    authorize! :manage_desc_metadata, @cocina

    catkey = @cocina.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
    if catkey.blank?
      render status: :bad_request, plain: 'object must have catkey to refresh descMetadata'
      return
    end

    Dor::Services::Client.object(@cocina.externalIdentifier).refresh_metadata

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Refreshed.' }
      else
        format.any { redirect_to solr_document_path(params[:id]), notice: "Metadata for #{@cocina.externalIdentifier} successfully refreshed from catkey: #{catkey}" }
      end
    end
  rescue Dor::Services::Client::UnexpectedResponse => e
    user_begin = 'An error occurred while attempting to refresh metadata'
    user_end = 'Please try again or contact the #dlss-infrastructure Slack channel for assistance.'
    logger.error "#{user_begin}: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: "#{user_begin}: #{e.message}. #{user_end}" }
  end

  # This is called from the item page and from the bulk (synchronous) update page
  def set_rights
    # Item may be a Collection or a DRO
    form_type = @cocina.collection? ? CollectionRightsForm : DRORightsForm
    form = form_type.new(@cocina)
    # The bulk form always uses `dro_rights_form` as the key
    form_key = params[:bulk] ? DRORightsForm.model_name.param_key : form.model_name.param_key
    form.validate(params[form_key])
    form.save

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Rights updated.' }
      else
        format.any { redirect_to solr_document_path(params[:id]), notice: 'Rights updated!' }
      end
    end
  rescue ArgumentError
    render status: :bad_request, plain: 'Invalid new rights setting.'
  end

  # set the rightsMetadata to the APO's defaultObjectRights
  def apply_apo_defaults
    @object.reapply_admin_policy_object_defaults
    save_and_reindex
    render status: :ok, plain: 'Defaults applied.'
  end

  def set_governing_apo
    return redirect_to solr_document_path(params[:id]), flash: { error: "Can't set governing APO on an invalid model" } if @cocina.is_a? NilModel

    authorize! :manage_governing_apo, @cocina, params[:new_apo_id]

    updated_administrative = @cocina.administrative.new(hasAdminPolicy: params[:new_apo_id])
    updated = @cocina.new(administrative: updated_administrative)
    object_client = Dor::Services::Client.object(@cocina.externalIdentifier)
    object_client.update(params: updated)
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

  def rights
    return redirect_to solr_document_path(params[:id]), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    form_type = @cocina.collection? ? CollectionRightsForm : DRORightsForm
    cocina_admin_policy = Dor::Services::Client.object(@cocina.administrative.hasAdminPolicy).find

    default_rights = RightsLabeler.label(cocina_admin_policy.administrative.defaultObjectRights)
    @form = form_type.new(@cocina, default_rights: default_rights)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def catkey_ui
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

  # Filters
  def create_obj
    @object = Dor.find params[:id]
  end

  def load_cocina
    raise 'missing druid' unless params[:id]

    @cocina = maybe_load_cocina(params[:id])
  end

  def save_and_reindex
    @object.save
    reindex
  end

  def reindex
    # Skip reindexing all bulk operations *except* bulk tag operations which do
    # require immediate reindexing since they do not touch Fedora (and thus do
    # not send messages to Solr)
    return if params[:bulk] && params[:tags].nil?

    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :manage_item, @cocina
  end

  def enforce_versioning
    return redirect_to solr_document_path(params[:id]), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if state_service.allows_modification?

    render status: :bad_request, plain: 'Object cannot be modified in its current state.'
    false
  end
end
# rubocop:enable Metrics/ClassLength
