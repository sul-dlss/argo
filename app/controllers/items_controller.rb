class ItemsController < ApplicationController
  require 'equivalent-xml'
  include ItemsHelper
  include DorObjectHelper
  include ModsDisplay::ControllerExtension
  before_action :authorize!
  before_action :create_obj, :except => [
    :open_bulk,
    :purge_object,
    :register
  ]
  before_action :forbid_modify, :only => [
    :add_collection, :set_collection, :remove_collection,
    :datastream_update,
    :mods,
    :open_version, :close_version,
    :update_resource,
    :set_content_type,
    :source_id,
    :tags, :tags_bulk,
    :update_rights,
    :update_attributes
  ]
  before_action :forbid_view, :only => [
    :get_file,
    :get_preserved_file
  ]
  before_action :enforce_versioning, :only => [
    :add_collection, :set_collection, :remove_collection,
    :source_id, :set_source_id,
    :set_content_type,
    :set_rights,
    :tags,
    :update_rights
  ]
  after_action :save_and_reindex, :only => [
    :add_collection, :set_collection, :remove_collection,
    :apply_apo_defaults,
    :embargo_update,
    :open_version, :close_version,
    :tags, :tags_bulk,
    :source_id,
    :set_rights,
    :set_content_type
  ]
  # must run after save_and_reindex
  prepend_after_action :flush_index, :only => [
    :add_workflow,
    :embargo_update
  ]

  def purl_preview
    @object.add_collection_reference @object.descMetadata.ng_xml
    @mods_display = ModsDisplayObject.new(@object.descMetadata.ng_xml.to_s)
  end

  # open a new version if needed. 400 if the item is in a state that doesnt allow opening a version.
  def prepare
    if can_open_version? @object.pid
      begin
        vers_md_upd_info = {
          :significance => params[:severity],
          :description => params[:description],
          :opening_user_name => current_user.to_s
        }
        @object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
      rescue Dor::Exception => e
        render :status => :precondition_failed, :text => e
        return
      end
    end
    render :status => :ok, :text => 'All good'
  end

  def close_version_ui
    @description = @object.datastreams['versionMetadata'].current_description
    @tag = @object.datastreams['versionMetadata'].current_tag

    # do some stuff to figure out which part of the version number changed when opening
    # the item for versioning, so that the form can pre-select the correct severity level
    @changed_severity = which_severity_changed(get_current_version_tag(@object), get_prior_version_tag(@object))
    @severity_selected = {}
    [:major, :minor, :admin].each do |severity|
      @severity_selected[severity] = (@changed_severity == severity)
    end
  end

  def set_collection
    can_set_collection = (@object.collections.size == 0)
    @object.add_collection(params[:collection]) if can_set_collection
    respond_to do |format|
      if params[:bulk]
        if can_set_collection
          format.html { render :status => :ok, :text => 'Collection set!' }
        else
          format.html { render :status => 500, :text => 'Collection not set, already has collection(s)' }
        end
      else
        msg = if can_set_collection
                'Collection successfully set'
              else
                'Collection not set, already has collection(s)'
              end
        format.html { redirect_to catalog_path(params[:id]), :notice => msg }
      end
    end
  end

  def add_collection
    @object.add_collection(params[:collection])
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Collection added!'}
      else
        format.html { redirect_to catalog_path(params[:id]), :notice => 'Collection successfully added' }
      end
    end
  end

  def remove_collection
    @object.remove_collection(params[:collection])
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Collection removed!'}
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Collection successfully removed' }
      end
    end
  end

  def register
    @perm_keys = current_user.groups
  end

  def workflow_history_view
    @history_xml = Dor::WorkflowService.get_workflow_xml 'dor', params[:id], nil
  end

  def mods
    respond_to do |format|
      format.xml  { render :xml => @object.descMetadata.content }
    end
  end

  ##
  # Renders a view with process-level state information for a given object's workflow.
  #
  # @option params [String] `:id` The druid for the object.
  # @option params [String] `:wf_name` The workflow name. e.g., accessionWF.
  # @option params [String] `:repo` The workflow's repository. e.g., dor.
  def workflow_view
    unless params[:wf_name].present? && params[:repo].present?
      fail ArgumentError, "Missing parameters: #{params.inspect}"
    end
    # Set variables for views; determine which workflow we're supposed to
    # render and honor a special value of 'workflow'
    @workflow_id = params[:wf_name]
    @workflow = if @workflow_id == 'workflow'
                  @object.workflows
                else
                  @object.workflows.get_workflow(@workflow_id, params[:repo])
                end
    respond_to do |format|
      format.js { render 'workflow_view', layout: false }
      format.html { render 'workflow_view' }
      format.xml  { render :xml => @workflow.ng_xml.to_xml }
      format.any(:png, :svg, :jpeg) do
        graph = @workflow.graph
        fail ActionController::RoutingError.new('Not Found') if graph.nil?
        send_data(
          graph.output(request.format.to_sym => String),
          :type => request.format.to_s,
          :disposition => 'inline'
        )
      end
    end
  end

  ##
  # Updates the status of a specific workflow process step to a given status.
  #
  # @option params [String] `:id` The druid for the object.
  # @option params [String] `:wf_name` The workflow name. e.g., accessionWF.
  # @option params [String] `:process` The workflow step. e.g., publish.
  # @option params [String] `:status` The status to which we want to reset the workflow.
  # @option params [String] `:repo` The repo to which the workflow applies (optional).
  def workflow_update
    args = params.values_at(:id, :wf_name, :process, :status)
    if args.all?(&:present?)
      # the :repo parameter is optional, so fetch it based on the workflow name if blank
      params[:repo] ||= Dor::WorkflowObject.find_by_name(params[:wf_name]).definition.repo
      # this will raise an exception if the item doesn't have that workflow step
      Dor::WorkflowService.get_workflow_status params[:repo], *args.take(3)
      # update the status for the step and redirect to the workflow view page
      Dor::WorkflowService.update_workflow_status params[:repo], *args
      respond_to do |format|
        if params[:bulk].present?
          render status: 200, text: 'Updated!'
        else
          msg = "Updated #{params[:process]} status to '#{params[:status]}' in #{params[:wf_name]}"
          format.any { redirect_to catalog_path(params[:id]), notice: msg }
        end
      end
    elsif params[:bulk].present?
      render status: :bad_request, text: 'Bad request!'
    else
      fail ArgumentError, "Missing arguments: #{args.inspect}"
    end
  end

  def release_hold
    # this will raise and exception if the item doesnt have that workflow step
    unless dor_accession_status(@object, 'sdr-ingest-transfer') == 'hold'
      render :status => :bad_request, :text => 'Item isnt on hold!'
      return
    end
    unless dor_lifecycle(@object.admin_policy_object, 'accessioned')
      render :status => :bad_request, :text => "Item's APO #{@object.admin_policy_object.pid} hasnt been ingested!"
      return
    end
    set_dor_accession_status(@object, 'sdr-ingest-transfer', 'waiting')
    if params[:bulk]
      render :status => 200, :text => 'Updated!'
      return
    end
    respond_to do |format|
      format.any { redirect_to catalog_path(@object.pid), :notice => 'Workflow was successfully updated' }
    end
  end

  def embargo_update
    unless current_user.is_admin
      render :status => :forbidden, :text => 'forbidden'
      return
    end
    fail ArgumentError, 'Missing embargo_date parameter' unless params[:embargo_date].present?
    @object.update_embargo(DateTime.parse(params[:embargo_date]).utc)
    @object.datastreams['events'].add_event('Embargo', current_user.to_s , 'Embargo date modified')
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Embargo was successfully updated' }
    end
  end

  ##
  # Brings up a modal dialog that lists all locations of the file
  # @option params [String] `:file` the filename for which to locate
  def file
    fail ArgumentError, 'Missing file parameter' unless params[:file].present?
    @available_in_workspace_error = nil
    @available_in_workspace = @object.list_files.include?(params[:file]) # NOTE: ideally this should be async
  rescue Net::SSH::Exception => e
    @available_in_workspace_error = "#{e.class}: #{e}"
  end

  ##
  # @option params [String] `:content` the XML with which to replace the datastream
  # @option params [String] `:dsid` the identifier for the datastream, e.g., `identityMetadata`
  # @option params [String] `:id` the druid to modify
  def datastream_update
    fail ArgumentError, 'Missing content' unless params[:content].present?
    fail ArgumentError, 'Missing datastream identifier' unless params[:dsid].present?
    begin
      # check that the content is well-formed xml
      Nokogiri::XML(params[:content]) { |config| config.strict }
    rescue Nokogiri::XML::SyntaxError
      fail ArgumentError, 'XML is not well formed!'
    end
    @object.datastreams[params[:dsid]].content = params[:content] # set the XML to be verbatim as posted

    # Catch reindexing errors here to avoid cascading errors
    begin
      save_and_reindex
    rescue ActiveFedora::ObjectNotFoundError
      render text: 'The object was not found in Fedora. Please recheck the RELS-EXT XML.', status: :not_found
      return
    end

    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Datastream was successfully updated' }
    end
  end

  def get_file
    data = @object.get_file(params[:file])
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=' + params[:file]
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = data
  end

  def get_preserved_file
    res = @object.get_preserved_file params[:file], params[:version]
    case res
    when Net::HTTPSuccess then
      response.headers['Content-Type'] = 'application/octet-stream'
      response.headers['Content-Disposition'] = 'attachment; filename=' + params[:file]
      response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
      self.response_body = res.body
    else
      raise res.value
    end
  end

  def update_attributes
    [:publish, :shelve, :preserve].each do |k|
      params[k] = (params[k].nil? || params[k] != 'on') ? 'no' : 'yes'
    end
    @object.contentMetadata.update_attributes(
      params[:file_name],
      params[:publish],
      params[:shelve],
      params[:preserve]
    )
    respond_to do |format|
      msg = "Updated attributes for file #{params[:file_name]}!"
      format.any { redirect_to catalog_path(params[:id]), notice: msg }
    end
  end

  # HELL. This makes:
  #  ~ 3-4 remote GET requests to WFS,
  #  ~ possibly 2 writes to WFS (each one triggers async object reindex),
  #  ~ plus an object save (more WFS requests, Fedora write, Solr reindex)
  def create_minimal_mods
    unless dor_accession_error?(@object, 'descriptive-metadata') ||
       dor_accession_error?(@object, 'publish')
      render status: 500, text: 'Object is not in error for descMD or publish!'
      return
    end
    unless @object.descMetadata.new?
      render status: 500, text: 'This service cannot overwrite existing data!'
      return
    end
    @object.descMetadata.content = ''
    @object.set_desc_metadata_using_label
    @object.save
    if dor_accession_error?(@object, 'descriptive-metadata')
      set_dor_accession_status(@object, 'descriptive-metadata', 'waiting')
    end
    if dor_accession_error?(@object, 'publish')
      set_dor_accession_status(@object, 'publish', 'waiting')
    end
    respond_to do |format|
      format.any { render :text => 'Set metadata' }
    end
  end

  def open_version
    # puts params[:description]
    vers_md_upd_info = {
      :significance => params[:severity],
      :description => params[:description],
      :opening_user_name => current_user.to_s
    }
    @object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
    respond_to do |format|
      msg = params[:id] + ' is open for modification!'
      format.any { redirect_to catalog_path(params[:id]), :notice => msg }
    end
  rescue StandardError => e
    raise e unless e.to_s == 'Object net yet accessioned'
    render :status => 500, :text => 'Object net yet accessioned'
    return
  end

  # create an instance of VersionTag for the current version of item
  # @return [String] current tag
  def get_current_version_tag(item)
    ds = item.datastreams['versionMetadata']
    Dor::VersionTag.parse(ds.tag_for_version(ds.current_version_id))
  end

  # create an instance of VersionTag for the second most recent version of item
  # @return [String] prior tag
  def get_prior_version_tag(item)
    ds = item.datastreams['versionMetadata']
    prior_version_id = (Integer(ds.current_version_id) - 1).to_s
    Dor::VersionTag.parse(ds.tag_for_version(prior_version_id))
  end

  # Given two instances of VersionTag, find the most significant difference
  # between the two (return nil if either one is nil or if they're the same)
  # @param [String] cur_version_tag   current version tag
  # @param [String] prior_version_tag prior version tag
  # @return [Symbol] :major, :minor, :admin or nil
  def which_severity_changed(cur_version_tag, prior_version_tag)
    return nil if cur_version_tag.nil? || prior_version_tag.nil?
    return :major if cur_version_tag.major != prior_version_tag.major
    return :minor if cur_version_tag.minor != prior_version_tag.minor
    return :admin if cur_version_tag.admin != prior_version_tag.admin
    nil
  end

  # as long as this isn't a bulk operation, and we get non-nil severity and description
  # values, update those fields on the version metadata datastream
  def close_version
    unless params[:bulk] || !params[:severity] || !params[:description]
      severity = params[:severity]
      desc = params[:description]
      ds = @object.versionMetadata
      ds.update_current_version({
        :description => desc,
        :significance => severity.to_sym
      })
      @object.save
    end

    begin
      @object.close_version
      msg = "Version #{@object.versionMetadata.current_version_id} closed"
      @object.datastreams['events'].add_event('close', current_user.to_s , msg)
      respond_to do |format|
        if params[:bulk]
          format.html {render :status => :ok, :text => 'Version Closed.'}
        else
          msg = "Version #{@object.current_version} of #{@object.pid} has been closed!"
          format.any { redirect_to catalog_path(params[:id]), :notice => msg }
        end
      end
    rescue Dor::Exception # => e
      render :status => 500, :text => 'No version to close.'
    end
  end

  # TODO: this should be a method in dor-services, invoked within set_source_id
  def self.normalize_source_id(new_source_id)
    src_id_arr = new_source_id.split(':').map(&:strip)
    raise 'new source_id must be of the form "source:value"' if src_id_arr.length != 2
    src_id_arr.join(':')
  end

  def source_id
    new_id = ItemsController.normalize_source_id(params[:new_id])
    @object.set_source_id(new_id)
    # TODO: the content= and content_will_change! calls belong in dor-services,
    # for this method and other similar methods. can then clean up
    # allow(idmd).to receive(:"ng_xml") (and "content_will_change!") in tests.
    # getting rid of "Metadata\.content\s*=\s*"
    @object.identityMetadata.content = @object.identityMetadata.ng_xml.to_xml
    @object.identityMetadata.content_will_change!
    respond_to do |format|
      if params[:bulk]
        format.html { render :status => :ok, :text => 'Updated source id.' }
      else
        msg = "Source Id for #{params[:id]} has been updated!"
        format.any { redirect_to catalog_path(params[:id]), :notice => msg }
      end
    end
  end

  def tags_bulk
    current_tags = @object.tags
    # delete all tags
    current_tags.each { |tag| @object.remove_tag tag }
    # add all of the recieved tags as new tags
    tags = params[:tags].split(/\t/)
    tags.each { |tag| @object.add_tag tag }
    @object.identityMetadata.content_will_change!  # mark as dirty
    @object.identityMetadata.save
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => "#{tags.size} Tags updated."}
      else
        msg = "#{tags.size} tags for #{params[:id]} have been updated!"
        format.any { redirect_to catalog_path(params[:id]), :notice => msg }
      end
    end
  end

  def tags
    current_tags = @object.tags
    if params[:add]
      [:new_tag1, :new_tag2, :new_tag3].each do |k|
        next unless params[k] && params[k].length > 0
        @object.add_tag(params[k])
      end
    end
    if params[:del]
      raise 'failed to delete' unless @object.remove_tag(current_tags[params[:tag].to_i - 1])
    end
    if params[:update]
      count = 1
      current_tags.each do |tag|
        @object.update_tag(tag, params[('tag' + count.to_s).to_sym])
        count += 1
      end
    end
    @object.identityMetadata.content_will_change!
    @object.identityMetadata.content = @object.identityMetadata.ng_xml.to_xml
    respond_to do |format|
      msg = "Tags for #{params[:id]} have been updated!"
      format.any { redirect_to catalog_path(params[:id]), :notice => msg }
    end
  end

  def purge_object
    begin
      create_obj
      return unless forbid_modify # return because rendering already happened
    rescue
      Dor::SearchService.solr.delete_by_id(params[:id])
      Dor::SearchService.solr.commit
    end
    if dor_lifecycle(@object, 'submitted')
      render :status => :forbidden, :text => 'Cannot purge an object after it is submitted.'
      return
    end
    @object.delete
    respond_to do |format|
      format.any { redirect_to '/', :notice => params[:id] + ' has been purged!' }
    end
  end

  def update_resource
    @object.move_resource(        params[:resource], params[:position]) if params[:position]
    @object.update_resource_label(params[:resource], params[:label   ]) if params[:label]
    @object.update_resource_type( params[:resource], params[:type    ]) if params[:type]
    acted = params[:position] || params[:label] || params[:type]
    @object.save if acted
    notice = (acted ? 'updated' : 'no action received for') + " resource #{params[:resource]}!"
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => notice }
    end
  end

  def discoverable
    messages = mods_discoverable @object.descMetadata.ng_xml
    if messages.length == 0
      render :status => :ok, :text => 'Discoverable.'
    else
      render :status => 500, :text => messages.join(' ')
    end
  end

  def remediate_mods
    render :status => :ok, :text => 'method disabled'
  end

  def schema_validation
    errors = schema_validate @object.descMetadata.ng_xml
    if errors.length == 0
      render :status => :ok, :text => 'Valid.'
    else
      render :status => 500, :text => errors.join('<br>')[0...490]
    end
  end

  def refresh_metadata
    @object.build_datastream('descMetadata', true)
    @object.descMetadata.content = @object.descMetadata.ng_xml.to_s
    @object.descMetadata.save
    render :status => :ok, :text => 'Refreshed.'
  end

  def scrubbed_content_ng_utf8(content)
    %w(amp lt gt quot).each do |char|
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
      render :status => :ok, :text => 'No change'
    else
      render :status => 500, :text => 'Has duplicates'
    end
  end

  def remove_duplicate_encoding
    ds = @object.descMetadata
    ng = scrubbed_content_ng_utf8(ds.content)
    if EquivalentXml.equivalent?(ng, ds.ng_xml)
      render :status => 500, :text => 'No duplicate encoding'
    else
      ds.ng_xml = ng
      ds.content = ng.to_s
      @object.save
      render :status => :ok, :text => 'Has duplicates'
    end
  end

  def set_rights
    unless %w(stanford world none dark).include? params[:rights]
      render :status => :forbidden, :text => 'Invalid new rights setting.'
      return
    end
    @object.set_read_rights(params[:rights])
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Rights updated.'}
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Rights updated!' }
      end
    end
  end
  # set the content type in the content metadata
  def set_content_type
    unless Constants::CONTENT_TYPES.include? params[:new_content_type]
      render :status => :forbidden, :text => 'Invalid new content type.'
      return
    end
    unless @object.datastreams.include? 'contentMetadata'
      render :status => :forbidden, :text => 'Object doesnt have a content metadata datastream to update.'
      return
    end
    @object.contentMetadata.set_content_type(
      params[:old_content_type],
      params[:old_resource_type],
      params[:new_content_type],
      params[:new_resource_type]
    )
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Content type updated.'}
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Content type updated!' }
      end
    end
  end

  # if an item errored in sdr-ingest-transfer due to missing provenance
  # metadata, create the datastream and reset the error
  def fix_missing_provenance
    if dor_accession_error?(@object, 'sdr-ingest-transfer') && @object.provenanceMetadata.new?
      @object.build_provenanceMetadata_datastream('accessionWF', 'DOR Common Accessioning completed')
      set_dor_accession_status(@object, 'sdr-ingest-transfer', 'waiting')
      render :text => 'ok.'
    else
      msg = 'Item not in error for sdr-ingest-transfer or provenance metadata already exists!'
      render :status => 500, :text => msg
    end
  end

  # set the rightsMetadata to the APO's defaultObjectRights
  def apply_apo_defaults
    @object.reapplyAdminPolicyObjectDefaults
    render :status => 200, :text => 'Defaults applied.'
  end

  # add a workflow to an object if the workflow is not present in the active table
  def add_workflow
    return unless params[:wf]
    wf_name = params[:wf]
    wf = @object.workflows[wf_name]
    # check the workflow is present and active (not archived)
    if wf && wf.active?
      render :status => 500, :text => "#{wf_name} already exists!"
      return
    end
    @object.create_workflow(wf_name)

    # We need to sync up the workflows datastream with workflow service (using #find)
    # and then force a committed Solr update before redirection.
    reindex Dor::Item.find(params[:id])
    msg = "Added #{wf_name}"

    if params[:bulk]
      render :text => msg
    else
      redirect_to catalog_path(params[:id]), notice: msg
    end
  end

  private

  def reindex(item)
    Dor::SearchService.solr.add item.to_solr
  end

  def flush_index
    Dor::SearchService.solr.commit
  end

  # Filters
  def create_obj
    raise 'missing druid' unless params[:id]
    @object = Dor::Item.find params[:id]
    @apo = @object.admin_policy_object
    @apo = ( @apo ? @apo.pid : '' )
  end

  def save_and_reindex
    @object.save
    reindex @object unless params[:bulk]
  end

  # ---
  # Permissions

  # check that the user can carry out this item modification
  def forbid_modify
    return true if current_user.is_admin || @object.can_manage_content?(current_user.roles(@apo))
    render :status => :forbidden, :text => 'forbidden'
    false
  end

  def forbid_view
    return true if current_user.is_admin || @object.can_view_content?(current_user.roles(@apo))
    render :status => :forbidden, :text => 'forbidden'
    false
  end

  def enforce_versioning
    # if this object has been submitted, doesnt have an open version, and isnt sitting at sdr-ingest with a hold, they cannot change it.
    return true if @object.allows_modification?
    render status: :forbidden, text: 'Object cannot be modified in its current state.'
    false
  end

  # ---
  # Dor::Workflow utils

  def dor_accession_error?(object, task)
    dor_accession_status(object, task) == 'error'
  end

  def dor_accession_status(object, task)
    Dor::WorkflowService.get_workflow_status('dor', object.pid, 'accessionWF', task)
  end

  def dor_lifecycle(object, stage)
    Dor::WorkflowService.get_lifecycle('dor', object.pid, stage)
  end

  def set_dor_accession_status(object, task, status)
    Dor::WorkflowService.update_workflow_status('dor', object.pid, 'accessionWF', task, status)
  end
end
