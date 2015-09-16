class ItemsController < ApplicationController
  before_filter :authorize!
  require 'net/ssh'
  require 'net/sftp'
  require 'equivalent-xml'
  include ItemsHelper
  include DorObjectHelper
  include ModsDisplay::ControllerExtension
  before_filter :create_obj, :except => [:register,:open_bulk, :purge_object]
  before_filter :forbid_modify, :only => [:add_collection, :set_collection, :remove_collection, :update_rights, :set_content_type, :tags, :tags_bulk, :source_id,:delete_file, :close_version, :open_version, :resource, :add_file, :replace_file,:update_attributes, :update_resource, :mods, :datastream_update ]
  before_filter :forbid_view,   :only => [:preserved_file, :get_file]
  before_filter :enforce_versioning, :only => [:add_collection, :set_collection, :remove_collection, :update_rights,:tags,:source_id,:set_source_id, :set_content_type,:set_rights]
  after_filter  :save_and_reindex,   :only => [:add_collection, :set_collection, :remove_collection, :open_version, :close_version, :tags, :tags_bulk, :source_id, :datastream_update, :set_rights, :set_content_type, :apply_apo_defaults]

  def purl_preview
    @object.add_collection_reference @object.descMetadata.ng_xml
    @mods_display = ModsDisplayObject.new(@object.descMetadata.ng_xml.to_s)
  end

  def crop
    @druid = params[:id].sub(/^druid:/,'')
    files = Legacy::Object.find_by_druid(@druid).files.find_all_by_file_role('00').sort { |a,b| a.id <=> b.id }
    @image_data = files.collect do |file|
      hash = file.webcrop
      hash[:fileSrc] = "#{ENV['RACK_BASE_URI']}/images/.dpg_pool/#{hash[:fileSrc]}"
      hash
    end
    render :crop, :layout => 'webcrop'
  end

  def save_crop
    @druid = params[:id].sub(/^druid:/,'')
    @image_data = JSON.parse(request.body.read)
    @image_data.each { |file_data|
      file_data.symbolize_keys!
      file_data[:cropCoords].symbolize_keys! if file_data.key?(:cropCoords)
      file = Legacy::File.find(file_data[:id])
      file.webcrop = file_data
    }
    render :json => @image_data.to_json
  end

  def on_hold
    %w(accession2WF accessionWF).each do |k|
      return true if (@object.workflows.include?(k) && Dor::WorkflowService.get_workflow_status('dor', pid, k, 'sdr-ingest-transfer') == 'hold')
    end
    return false
  rescue
    return false
  end

  #open a new version if needed. 400 if the item is in a state that doesnt allow opening a version.
  def prepare
    if can_open_version? @object.pid
      begin
        vers_md_upd_info = {:significance => params[:severity], :description => params[:description], :opening_user_name => current_user.to_s}
        @object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
      rescue Dor::Exception => e
        render :status=> :precondition_failed, :text => e
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
      @severity_selected[severity] = (@changed_severity == severity ? " selected" : "")
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
        if can_set_collection
          format.html { redirect_to catalog_path(params[:id]), :notice => 'Collection successfully set' }
        else
          format.html { redirect_to catalog_path(params[:id]), :notice => 'Collection not set, already has collection(s)' }
        end
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
    @perm_keys = ["sunetid:#{current_user.login}"]
    if webauth && webauth.privgroup.present?
      @perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end
    render :register, :layout => 'application'
  end

  def workflow_view
    @obj=@object
    @workflow_id = params[:wf_name]
    @workflow = @workflow_id == 'workflow' ? @obj.workflows : @obj.workflows.get_workflow(@workflow_id, params[:repo])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @workflow.ng_xml.to_xml }
      format.any(:png,:svg,:jpeg) {
        graph = @workflow.graph
        raise ActionController::RoutingError.new('Not Found') if graph.nil?
        image_data = graph.output(request.format.to_sym => String)
        send_data image_data, :type => request.format.to_s, :disposition => 'inline'
      }
    end
  end

  def workflow_history_view
    @history_xml=Dor::WorkflowService.get_workflow_xml 'dor', params[:id], nil
  end

  def mods
    respond_to do |format|
      format.xml  { render :xml => @object.descMetadata.content }
    end
  end

  def workflow_update
    args = params.values_at(:id, :wf_name, :process, :status)
    check_args = params.values_at(:id, :wf_name, :process)

    if args.all? &:present?
      #this will raise and exception if the item doesnt have that workflow step
      Dor::WorkflowService.get_workflow_status params[:repo], *check_args
      Dor::WorkflowService.update_workflow_status params[:repo], *args
      @item = Dor.find params[:id]

      respond_to do |format|
        if params[:bulk]
          render :status => 200, :text => 'Updated!'
          return
        end
        format.any { redirect_to workflow_view_item_path(@item.pid, params[:wf_name],:repo => params[:repo]), :notice => 'Workflow was successfully updated' }
      end
    else
      respond_to do |format|
        if params[:bulk]
          render :status => :bad_request, :text => 'Bad request!'
          return
        end
        format.any { render format.to_sym => 'Bad Request', :status => :bad_request }
      end
    end
  end

  def release_hold
    #this will raise and exception if the item doesnt have that workflow step
    unless Dor::WorkflowService.get_workflow_status('dor', @object.pid, 'accessionWF','sdr-ingest-transfer') == 'hold'
      render :status => :bad_request, :text => 'Item isnt on hold!'
      return
    end
    unless Dor::WorkflowService.get_lifecycle('dor', @object.admin_policy_object.pid, 'accessioned')
      render :status => :bad_request, :text => "Item's APO #{@object.admin_policy_object.pid} hasnt been ingested!"
      return
    end
    Dor::WorkflowService.update_workflow_status 'dor', @object.pid, 'accessionWF','sdr-ingest-transfer','waiting'
    respond_to do |format|
      if params[:bulk]
        render :status => 200, :text => 'Updated!'
        return
      end
      format.any { redirect_to catalog_path(@object.pid), :notice => 'Workflow was successfully updated' }
    end
  end

  def embargo_update
    if current_user.is_admin
      new_date=DateTime.parse(params[:embargo_date])
      @object.update_embargo(new_date)
      @object.datastreams['events'].add_event("Embargo", current_user.to_s , "Embargo date modified")
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Embargo was successfully updated' }
      end
    else
      render :status=> :forbidden, :text =>'forbidden'
    end
  end

  def datastream_update
    ds=@object.datastreams[params[:dsid]]
    #check that the content is valid xml
    begin
      content=Nokogiri::XML(params[:content]){ |config| config.strict }
    rescue
      raise 'XML was not well formed!'
    end
    ds.content=content.to_s
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Datastream was successfully updated' }
    end
  end

  def get_file
    data=@object.get_file(params[:file])
    self.response.headers["Content-Type"] = "application/octet-stream"
    self.response.headers["Content-Disposition"] = "attachment; filename="+params[:file]
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s
    self.response_body = data
  end

  def get_preserved_file
    res=@object.get_preserved_file params[:file], params[:version]
    case res
    when Net::HTTPSuccess then
      self.response.headers["Content-Type"] = "application/octet-stream"
      self.response.headers["Content-Disposition"] = "attachment; filename="+params[:file]
      self.response.headers['Last-Modified'] = Time.now.ctime.to_s
      self.response_body = res.body
    else
      raise res.value
    end
  end

  def update_attributes
    [:publish, :shelve, :preserve].each do |k|
      params[k] = (params[k].nil? || params[k]!='on') ? 'no' : 'yes'
    end
    @object.contentMetadata.update_attributes(params[:file_name], params[:publish], params[:shelve], params[:preserve])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Updated attributes for file '+params[:file_name]+'!' }
    end
  end

  def create_minimal_mods
    unless (Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'descriptive-metadata')=='error' || Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'publish')=='error')
      render :text => 'Object is not in error for descMD or publish!', :status => 500
      return
    end
    unless @object.descMetadata.new?
      render :text => 'This service cannot overwrite existing data!', :status => 500
      return
    end
    @object.descMetadata.content=''
    @object.set_desc_metadata_using_label
    @object.save
    if Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'descriptive-metadata')=='error'
      Dor::WorkflowService.update_workflow_status 'dor', @object.id, 'accessionWF', 'descriptive-metadata', 'waiting'
    end
    if Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'publish')=='error'
      Dor::WorkflowService.update_workflow_status 'dor', @object.id, 'accessionWF', 'publish', 'waiting'
    end
    respond_to do |format|
      format.any { render :text => 'Set metadata ' }
    end
  end

  def replace_file
    @object.replace_file params[:uploaded_file],params[:file_name]
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'File '+params[:file_name]+' was replaced!' }
    end
  end
  #add a file to a resource, not to be confused with add a resource to an object
  def add_file
    item=Dor::Item.find(params[:id])
    item.add_file params[:uploaded_file],params[:resource],params[:uploaded_file].original_filename, Rack::Mime.mime_type(File.extname(params[:uploaded_file].original_filename))
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'File '+params[:uploaded_file].original_filename+' was added!' }
    end
  end

  def open_version
    # puts params[:description]
    vers_md_upd_info = {:significance => params[:severity], :description => params[:description], :opening_user_name => current_user.to_s}
    @object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => params[:id]+' is open for modification!' }
    end
  rescue StandardError => e
    raise e unless e.to_s == 'Object net yet accessioned'
    render :status=> 500, :text =>'Object net yet accessioned'
    return
  end

  def get_current_version_tag(item)
    # create an instance of VersionTag for the current version of item
    ds = item.datastreams['versionMetadata']
    cur_version_id = ds.current_version_id
    cur_tag = Dor::VersionTag.parse(ds.tag_for_version(cur_version_id))
    return cur_tag
  end

  def get_prior_version_tag(item)
    # create an instance of VersionTag for the second most recent version of item
    ds = item.datastreams['versionMetadata']
    prior_version_id = (Integer(ds.current_version_id)-1).to_s
    prior_tag = Dor::VersionTag.parse(ds.tag_for_version(prior_version_id))
    return prior_tag
  end

  def which_severity_changed(cur_version_tag, prior_version_tag)
    # given two instances of VersionTag, find the most significant part of the field which changed
    # between the two (return nil if either instance is nil or if they're the same)
    if cur_version_tag.nil? || prior_version_tag.nil?
      return nil
    elsif cur_version_tag.major != prior_version_tag.major
      return :major
    elsif cur_version_tag.minor != prior_version_tag.minor
      return :minor
    elsif cur_version_tag.admin != prior_version_tag.admin
      return :admin
    else
      return nil
    end
  end

  def close_version
    # as long as this isn't a bulk operation, and we get non-nil severity and description
    # values, update those fields on the version metadata datastream
    unless (params[:bulk] || !params[:severity] || !params[:description])
      severity = params[:severity]
      desc = params[:description]
      ds = @object.versionMetadata
      ds.update_current_version({:description => desc, :significance => severity.to_sym})
      @object.save
    end

    begin
      @object.close_version
      @object.datastreams['events'].add_event("close", current_user.to_s , "Version "+ @object.versionMetadata.current_version_id.to_s + " closed")
      respond_to do |format|
        if params[:bulk]
          format.html {render :status => :ok, :text => 'Version Closed.'}
        else
          format.any { redirect_to catalog_path(params[:id]), :notice => 'Version '+@object.current_version+' of '+params[:id]+' has been closed!' }
        end
      end
    rescue Dor::Exception # => e
      render :status => 500, :text => 'No version to close.'
    end
  end

  def source_id
    new_id=params[:new_id].strip
    @object.set_source_id(new_id)
    #TODO: the content= and content_will_change! calls belong in dor-services, for this method and other similar methods.
    # can then clean up allow(idmd).to receive(:"ng_xml") (and "content_will_change!") in tests.
    @object.identityMetadata.content = @object.identityMetadata.ng_xml.to_xml
    @object.identityMetadata.content_will_change!
    respond_to do |format|
      if params[:bulk]
        format.html { render :status => :ok, :text => 'Updated source id.' }
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Source Id for '+params[:id]+' has been updated!' }
      end
    end
  end

  def tags_bulk
    current_tags=@object.tags
    #delete all tags
    current_tags.each do |cur_tag|
      @object.remove_tag cur_tag
    end
    #add all of the recieved tags as new tags
    tags=params[:tags].split(/\t/)
    tags.each do |tag|
      @object.add_tag tag
    end
    @object.identityMetadata.content_will_change!  # mark as dirty
    @object.identityMetadata.save
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Tags updated.'}
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Tags for '+params[:id]+' have been updated!' }
      end
    end
  end

  def tags
    current_tags=@object.tags
    if params[:add]
      [:new_tag1,:new_tag2,:new_tag3].each do |k|
        next unless (params[k] && params[k].length > 0)
        @object.add_tag(params[k])
      end
    end
    if params[:del]
      raise 'failed to delete' unless @object.remove_tag(current_tags[params[:tag].to_i - 1])
    end
    if params[:update]
      count = 1
      current_tags.each do |tag|
        @object.update_tag(tag,params[('tag'+count.to_s).to_sym])
        count+=1
      end
    end
    @object.identityMetadata.content_will_change!
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Tags for '+params[:id]+' have been updated!' }
    end
  end

  def delete_file
    @object.remove_file(params[:file_name])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => params[:file_name] + ' has been deleted!' }
    end
  end

  def resource
    @content_ds = @object.datastreams['contentMetadata']
  end

  def purge_object
    begin
      create_obj
      #return because rendering already happened
      return unless forbid_modify
    rescue
      Dor::SearchService.solr.delete_by_id(params[:id])
      Dor::SearchService.solr.commit
    end
    if Dor::WorkflowService.get_lifecycle('dor', @object.pid, 'submitted')
      render :status=> :forbidden, :text =>'Cannot purge an object after it is submitted.'
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
    notice = (acted ? "updated" : "no action received for") + " resource #{params[:resource]}!"
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
    @object.build_datastream('descMetadata',true)
    @object.descMetadata.content = @object.descMetadata.ng_xml.to_s
    @object.descMetadata.save
    render :status => :ok, :text => 'Refreshed.'
  end

  def scrubbed_content_ng_utf8(content)
    %w(amp lt gt quot).each do |char|
      content=content.gsub('&amp;'+char+';', '&'+char+';')
    end
    content=content.gsub(/&amp;(\#[0-9]+;)/, '&\1')
    content=content.gsub(/&amp;(\#x[0-9A-Fa-f];)/, '&\1')
    Nokogiri::XML(content,nil,'UTF-8')
  end

  def detect_duplicate_encoding
    ds=@object.descMetadata
    ng=scrubbed_content_ng_utf8(ds.content)
    if EquivalentXml.equivalent?(ng, ds.ng_xml)
      render :status => :ok, :text => 'No change'
    else
      render :status => 500, :text => 'Has duplicates'
    end
  end

  def change_mods_value
    mods=Mods::Reader.new(@object.descMetadata.content)
    return unless mods.methods.include? params[:field].to_sym
    mods.send(params[:field].to_sym, params[:val])
  end

  def remove_duplicate_encoding
    ds=@object.descMetadata
    ng=scrubbed_content_ng_utf8(ds.content)
    if EquivalentXml.equivalent?(ng, ds.ng_xml)
      render :status => 500, :text => 'No duplicate encoding'
    else
      ds.ng_xml=ng
      ds.content=ng.to_s
      @object.save
      render :status => :ok, :text => 'Has duplicates'
    end
  end

  def set_rights
    unless %w(stanford world none dark).include? params[:rights]
      render :status=> :forbidden, :text =>'Invalid new rights setting.'
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
  #set the content type in the content metadata
  def set_content_type
    unless %w(book file image map manuscript).include? params[:new_content_type]
      render :status=> :forbidden, :text =>'Invalid new content type.'
      return
    end
    unless @object.datastreams.include? 'contentMetadata'
      render :status=> :forbidden, :text =>'Object doesnt have a content metadata datastream to update.'
      return
    end
    @object.contentMetadata.set_content_type(params[:old_content_type], params[:old_resource_type], params[:new_content_type], params[:new_resource_type])
    respond_to do |format|
      if params[:bulk]
        format.html {render :status => :ok, :text => 'Content type updated.'}
      else
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Content type updated!' }
      end
    end
  end

  #if an item errored in sdr-ingest-transfer due to missing provenance metadata, create the datastream and reset the error
  def fix_missing_provenance
    if Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'sdr-ingest-transfer') =='error' && @object.provenanceMetadata.new?
      @object.build_provenanceMetadata_datastream('accessionWF','DOR Common Accessioning completed')
      Dor::WorkflowService.update_workflow_status 'dor', @object.id, 'accessionWF', 'sdr-ingest-transfer', 'waiting'
      render :text => 'ok.'
    else
      render :status => 500, :text => "Item not in error for sdr-ingest-transfer or provenance metadata already exists!"
    end
  end

  #set the rightsMetadata to the APO's defaultObjectRights
  def apply_apo_defaults
    @object.reapplyAdminPolicyObjectDefaults
    render :status=> 200, :text =>'Defaults applied.'
  end

  #add a workflow to an object if the workflow is not present in the active table
  def add_workflow
    return unless params[:wf]
    wf = @object.workflows[params[:wf]]
    #check for this workflow is present and active (not archived)
    if wf && wf.active?
      render :status => 500, :text => "#{params[:wf]} already exists!"
      return
    end
    @object.initialize_workflow(params[:wf])
    if params[:bulk]
      render :text => "Added #{params[:wf]}"
    else
      redirect_to catalog_path(params[:id]), :notice => "Added #{params[:wf]}"
    end
  end

  private

  def reindex item
    doc=item.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end

  # Filters
  def create_obj
    raise 'missing druid' unless params[:id]
    begin
      @object = Dor::Item.find params[:id]
      @apo=@object.admin_policy_object
      @apo=( @apo ? @apo.pid : '' )
    rescue ActiveFedora::ObjectNotFoundError # => e
      render :status=> 500, :text =>'Object doesnt exist in Fedora.'
      return
    end
  end

  def save_and_reindex
    @object.save
    reindex @object unless (params[:bulk])
  end

  #check that the user can carry out this item modification
  def forbid_modify
    return true if current_user.is_admin || @object.can_manage_content?(current_user.roles @apo)
    render :status=> :forbidden, :text =>'forbidden'
    return false
  end

  def forbid_view
    return true if current_user.is_admin || @object.can_view_content?(current_user.roles @apo)
    render :status=> :forbidden, :text =>'forbidden'
    return false
  end

  def enforce_versioning
    #if this object has been submitted, doesnt have an open version, and isnt sitting at sdr-ingest with a hold, they cannot change it.
    return true if @object.allows_modification? || on_hold
    render :status=> :forbidden, :text =>'Object cannot be modified in its current state.'
    return false
  end
end
