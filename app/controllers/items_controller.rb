# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ItemsController < ApplicationController
  include ModsDisplay::ControllerExtension
  before_action :create_obj, except: %i[
    purl_preview
    open_bulk
    register
  ]
  before_action :authorize_manage!, only: %i[
    add_collection set_collection remove_collection
    datastream_update
    mods
    purge_object
    update_resource
    source_id
    catkey
    tags
    update_rights
    update_attributes
    embargo_update
    embargo_form
  ]

  before_action :authorize_manage_desc_metadata!, only: [
    :refresh_metadata
  ]
  before_action :authorize_set_governing_apo!, only: [
    :set_governing_apo
  ]
  before_action :enforce_versioning, only: %i[
    add_collection set_collection remove_collection
    source_id set_source_id
    catkey
    refresh_metadata
    set_rights
    set_governing_apo
    update_rights
  ]

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
    @object.collections.each { |collection| @object.remove_collection(collection.pid) } # first remove any existing collections
    if params[:collection].present?
      @object.add_collection(params[:collection]) # collection provided, so add it
      response_message = 'Collection successfully set.'
    else
      response_message = 'Collection(s) successfully removed.' # no collection selected from drop-down, so don't bother adding a new one
    end
    save_and_reindex
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
          new_collection_html = render_to_string('items/_collection_ui_line_item', formats: [:html], layout: false, locals: { col: Dor.find(params[:collection]) })
          render status: :ok, plain: { 'message': response_message, 'new_collection_html': new_collection_html }.to_json
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
        format.json { render status: :ok, plain: { 'message': response_message, 'druid': params[:collection].gsub('druid:', '') }.to_json }
        format.any  { redirect_to solr_document_path(params[:id]), notice: response_message }
      end
    end
  end

  def register
    @perm_keys = current_user.groups
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

    save_and_reindex
    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: 'Embargo was successfully updated' }
    end
  end

  ##
  # @option params [String] `:content` the XML with which to replace the datastream
  # @option params [String] `:dsid` the identifier for the datastream, e.g., `identityMetadata`
  # @option params [String] `:id` the druid to modify
  def datastream_update
    raise ArgumentError, 'Missing content' unless params[:content].present?
    raise ArgumentError, 'Missing datastream identifier' unless params[:dsid].present?

    begin
      # check that the content is well-formed xml
      Nokogiri::XML(params[:content], &:strict)
    rescue Nokogiri::XML::SyntaxError
      raise ArgumentError, 'XML is not well formed!'
    end
    @object.datastreams[params[:dsid]].content = params[:content] # set the XML to be verbatim as posted
    save_and_reindex

    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: 'Datastream was successfully updated' }
    end
  end

  def update_attributes
    %i[publish shelve preserve].each do |k|
      params[k] = params[k].nil? || params[k] != 'on' ? 'no' : 'yes'
    end
    @object.contentMetadata.update_attributes(
      params[:file_name],
      params[:publish],
      params[:shelve],
      params[:preserve]
    )
    respond_to do |format|
      msg = "Updated attributes for file #{params[:file_name]}!"
      format.any { redirect_to solr_document_path(params[:id]), notice: msg }
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
    @object.source_id = params[:new_id]
    save_and_reindex

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
    @object.catkey = params[:new_catkey].strip
    save_and_reindex

    respond_to do |format|
      if params[:bulk]
        format.html { render status: :ok, plain: 'Updated catkey' }
      else
        msg = "Catkey for #{params[:id]} has been updated!"
        format.any { redirect_to solr_document_path(params[:id]), notice: msg }
      end
    end
  end

  def tags
    current_tags = tags_client.list

    if params[:add]
      tags = params.slice(:new_tag1, :new_tag2, :new_tag3).values.reject(&:empty?)
      tags_client.create(tags: tags) if tags.any?
    end

    if params[:del]
      tag_to_delete = current_tags[params[:tag].to_i - 1]
      raise 'failed to delete' unless tags_client.destroy(tag: tag_to_delete)
    end

    if params[:update]
      count = 1
      current_tags.each do |tag|
        tags_client.update(current: tag, new: params["tag#{count}".to_sym])
        count += 1
      end
    end

    reindex
    respond_to do |format|
      msg = "Tags for #{params[:id]} have been updated!"
      format.any { redirect_to solr_document_path(params[:id]), notice: msg }
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

  def update_resource
    @object.move_resource(params[:resource], params[:position]) if params[:position]
    @object.update_resource_label(params[:resource], params[:label]) if params[:label]
    @object.update_resource_type(params[:resource], params[:type]) if params[:type]
    acted = params[:position] || params[:label] || params[:type]
    @object.save if acted
    notice = (acted ? 'updated' : 'no action received for') + " resource #{params[:resource]}!"
    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: notice }
    end
  end

  def discoverable
    messages = mods_discoverable @object.descMetadata.ng_xml
    if messages.empty?
      render status: :ok, plain: 'Discoverable.'
    else
      render status: :internal_server_error, plain: messages.join(' ')
    end
  end

  def remediate_mods
    render status: :ok, plain: 'method disabled'
  end

  def schema_validation
    errors = schema_validate @object.descMetadata.ng_xml
    if errors.empty?
      render status: :ok, plain: 'Valid.'
    else
      render status: :internal_server_error, plain: errors.join('<br>')[0...490]
    end
  end

  def refresh_metadata
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
    user_end = 'Please try again or contact the sdr-operations Slack channel for assistance.'
    Rails.logger.error "#{user_begin}: #{e.message}"
    redirect_to solr_document_path(params[:id]), flash: { error: "#{user_begin}: #{e.message}. #{user_end}" }
  end

  def scrubbed_content_ng_utf8(content)
    %w[amp lt gt quot].each do |char|
      content = content.gsub('&amp;' + char + ';', '&' + char + ';')
    end
    content = content.gsub(/&amp;(\#[0-9]+;)/, '&\1')
    content = content.gsub(/&amp;(\#x[0-9A-Fa-f];)/, '&\1')
    Nokogiri::XML(content, nil, 'UTF-8')
  end

  def detect_duplicate_encoding
    ds = @object.descMetadata
    ng = scrubbed_content_ng_utf8(ds.content)
    if EquivalentXml.equivalent?(ng, ds.ng_xml)
      render status: :ok, plain: 'No change'
    else
      render status: :internal_server_error, plain: 'Has duplicates'
    end
  end

  def remove_duplicate_encoding
    ds = @object.descMetadata
    ng = scrubbed_content_ng_utf8(ds.content)
    if EquivalentXml.equivalent?(ng, ds.ng_xml)
      render status: :internal_server_error, plain: 'No duplicate encoding'
    else
      ds.ng_xml = ng
      ds.content = ng.to_s
      @object.save
      render status: :ok, plain: 'Has duplicates'
    end
  end

  # This is called from the item page and from the bulk (synchronous) update page
  def set_rights
    @object.read_rights = params[:access_form][:rights]
    save_and_reindex

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
    if params[:bulk]
      render status: :gone, plain: 'the old bulk update mechanism is deprecated.  please use the new bulk actions framework going forward.'
      return
    end

    @object.admin_policy_object = Dor.find(params[:new_apo_id])
    @object.identityMetadata.adminPolicy = nil if @object.identityMetadata.adminPolicy # no longer supported, erase if present as a bit of remediation
    save_and_reindex
    redirect_to solr_document_path(params[:id]), notice: 'Governing APO updated!'
  end

  def collection_ui
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def rights
    object_client = Dor::Services::Client.object(params[:id])

    begin
      cocina = object_client.find
    rescue Dor::Services::Client::UnexpectedResponse
      cocina = NilModel.new(params[:id])
    end
    @form = AccessForm.new(cocina)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def tags_ui
    @pid = @object.pid
    @tags = tags_client.list

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

  def tags_client
    Dor::Services::Client.object(@object.pid).administrative_tags
  end

  # Filters
  def create_obj
    raise 'missing druid' unless params[:id]

    @object = Dor.find params[:id]
    @apo = @object.admin_policy_object
    @apo = (@apo ? @apo.pid : '')
  end

  def save_and_reindex
    @object.save
    reindex
  end

  def reindex
    # Skip reindexing all bulk operations *except* bulk tag operations which do
    # require immediate reindexing since they do not touch Fedora (and thus do
    # not send messages to Solr)
    return if params[:bulk]

    Argo::Indexer.reindex_pid_remotely(@object.pid)
  end

  # ---
  # Permissions

  def authorize_manage!
    authorize! :manage_item, @object
  end

  def authorize_manage_desc_metadata!
    authorize! :manage_desc_metadata, @object
  end

  def enforce_versioning
    state_service = StateService.new(@object.pid, version: @object.current_version)

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if state_service.allows_modification?

    render status: :bad_request, plain: 'Object cannot be modified in its current state.'
    false
  end

  def authorize_set_governing_apo!
    authorize! :manage_governing_apo, @object, params[:new_apo_id]
  end

  # ---
  # Dor::Workflow utils

  def dor_lifecycle(object, stage)
    WorkflowClientFactory.build.lifecycle(druid: object.pid, milestone_name: stage)
  end
end
# rubocop:enable Metrics/ClassLength
