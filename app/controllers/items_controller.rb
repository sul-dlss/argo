# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ItemsController < ApplicationController
  include ModsDisplay::ControllerExtension
  before_action :create_obj, except: :purl_preview
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
    return redirect_to solr_document_path(params[:id]), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

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
    if params[:collection].present?
      @object.add_collection(params[:collection])
      save_and_reindex
      response_message = 'Collection added successfully'
    else
      response_message = 'No collection selected'
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
                                                                                     item_id: @object.id
                                                                                   })
          render status: :ok, plain: { message: response_message, new_collection_html: new_collection_html }.to_json
        end
        format.html { redirect_to solr_document_path(params[:id]), notice: response_message }
      end
    end
  end

  def remove_collection
    @object.remove_collection(params[:collection])
    save_and_reindex
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
    respond_to do |format|
      format.xml  { render xml: @object.descMetadata.content }
    end
  end

  def embargo_update
    raise ArgumentError, 'Missing embargo_date parameter' unless params[:embargo_date].present?

    object_client = Dor::Services::Client.object(@object.pid)
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
    object_client = Dor::Services::Client.object(@object.pid)
    dro = object_client.find
    updated_identification = dro.identification.new(sourceId: params[:new_id])
    updated = dro.new(identification: updated_identification)
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
    if dor_lifecycle(@object, 'submitted')
      render status: :bad_request, plain: 'Cannot purge an object after it is submitted.'
      return
    end

    @object.delete
    WorkflowClientFactory.build.delete_all_workflows(pid: @object.pid)
    ActiveFedora.solr.conn.delete_by_id(params[:id])
    ActiveFedora.solr.conn.commit

    redirect_to '/', notice: params[:id] + ' has been purged!'
  end

  def refresh_metadata
    authorize! :manage_desc_metadata, @object

    if @object.catkey.blank?
      render status: :bad_request, plain: 'object must have catkey to refresh descMetadata'
      return
    end

    Dor::Services::Client.object(@object.pid).refresh_metadata

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Refreshed.' }
      else
        format.any { redirect_to solr_document_path(params[:id]), notice: "Metadata for #{@object.pid} successfully refreshed from catkey: #{@object.catkey}" }
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
    return redirect_to solr_document_path(params[:id]), flash: { error: "Can't set rights on an invalid model" } if @cocina.is_a? NilModel

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
    object_client = Dor::Services::Client.object(@object.id)
    @collection_list = object_client.collections
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def rights
    return redirect_to solr_document_path(params[:id]), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    form_type = @cocina.collection? ? CollectionRightsForm : DRORightsForm

    @form = form_type.new(@cocina, default_rights: @object.admin_policy_object.default_rights)

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
    raise 'missing druid' unless params[:id]

    @cocina = maybe_load_cocina(params[:id])

    @object = Dor.find params[:id]
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

    Argo::Indexer.reindex_pid_remotely(@object.pid)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :manage_item, @cocina
  end

  def enforce_versioning
    state_service = StateService.new(@object.pid, version: @object.current_version)

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if state_service.allows_modification?

    render status: :bad_request, plain: 'Object cannot be modified in its current state.'
    false
  end

  # ---
  # Dor::Workflow utils

  def dor_lifecycle(object, stage)
    WorkflowClientFactory.build.lifecycle(druid: object.pid, milestone_name: stage)
  end
end
# rubocop:enable Metrics/ClassLength
