class ItemsController < ApplicationController
  before_filter :authorize!
  require 'net/ssh'
  require 'net/sftp'
  require 'equivalent-xml'
  include ItemsHelper
  include ModsDisplay::ControllerExtension
  before_filter :create_obj, :except => [:register,:open_bulk, :purge_object]
  before_filter :forbid_modify, :only => [:add_collection, :remove_collection, :update_rights, :set_content_type, :tags, :tags_bulk, :source_id,:delete_file, :close_version, :open_version, :resource, :add_file, :replace_file,:update_attributes, :update_resource, :update_mods, :mods, :datastream_update ]
  before_filter :forbid_view, :only => [:preserved_file, :get_file]
  before_filter :enforce_versioning, :only => [:add_collection, :remove_collection, :update_rights,:tags,:source_id,:set_source_id,:set_content_type,:set_rights]
  after_filter :save_and_reindex, :only => [:add_collection, :remove_collection, :open_version, :close_version, :tags, :tags_bulk, :source_id, :datastream_update, :set_rights, :set_content_type, :apply_apo_defaults]

  #this empty config block is recommended by jkeck due to potential misconfiguration without it. That should be fixed in >= 0.1.4
  configure_mods_display do
  end
  
  def purl_preview
    @mods_display=ModsDisplayObject.new(@object.add_collection_reference)
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
      file_data[:cropCoords].symbolize_keys! if file_data.has_key?(:cropCoords)
      file = Legacy::File.find(file_data[:id])
      file.webcrop = file_data
    }
    render :json => @image_data.to_json
  end
  def on_hold
    begin
      if (@object.workflows.include?('accession2WF') and Dor::WorkflowService.get_workflow_status('dor', pid, 'accessionWF2', 'sdr-ingest-transfer')=='hold') or (@object.workflows.include?('accessionWF') and Dor::WorkflowService.get_workflow_status('dor', pid, 'accessionWF', 'sdr-ingest-transfer')=='hold')
        true
      else
        false
      end
    rescue
      return false
    end
  end
  #open a new version if needed. 400 if the item is in a state that doesnt allow opening a version. 
  def prepare

    if not  Dor::WorkflowService.get_lifecycle('dor', @object.pid, 'submitted' ) or on_hold
      #this item hasnt been submitted yet, it can be modified
    else
      #this item must go though versioning, is it already open?
      if @object.new_version_open?

      else
        #can it be opened?
        begin
          @object.open_new_version
          @object.datastreams['events'].add_event("open", current_user.to_s , "Version "+ @object.versionMetadata.current_version_id.to_s + " opened")
          @object.save
          severity=params[:severity]
          desc=params[:description]
          ds=@object.versionMetadata
          ds.update_current_version({:description => desc,:significance => severity.to_sym})
        rescue Dor::Exception => e
          render :status=> :precondition_failed, :text => e
          return;
        end
      end
    end
    render :status => :ok, :text => 'All good'
  end
  def close_version_ui
    @description = @object.datastreams['versionMetadata'].current_description
    @tag = @object.datastreams['versionMetadata'].current_tag
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
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Collection successfully removed' }
    end
  end

  def register
    @perm_keys = ["sunetid:#{current_user.login}"] 
    if webauth and webauth.privgroup.present?
      @perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end
    render :register, :layout => 'application'
  end

  def workflow_view
    @obj=@object
    @workflow_id = params[:wf_name]
    @repo=params[:repo] #pass this to workflow queries
    @workflow = @workflow_id == 'workflow' ? @obj.workflows : @obj.workflows.get_workflow(@workflow_id,@repo)

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
      format.html
    end
  end
  def update_mods
    @object.descMetadata.content=params[:xmlstr]
    @object.save
    respond_to do |format|
      format.xml  { render :xml => @object.descMetadata.ng_xml.to_s }
    end
  end
  def workflow_update
    
    @item=@object
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
    if not Dor::WorkflowService.get_workflow_status('dor', @object.pid, 'accessionWF','sdr-ingest-transfer') == 'hold'
      render :status => :bad_request, :text => 'Item isnt on hold!'
      return
    end
    if not Dor::WorkflowService.get_lifecycle('dor', @object.admin_policy_object.pid, 'accessioned')
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
    if not current_user.is_admin
      render :status=> :forbidden, :text =>'forbidden'
    else
      new_date=DateTime.parse(params[:embargo_date])
      @object.update_embargo(new_date)
      @object.datastreams['events'].add_event("Embargo", current_user.to_s , "Embargo date modified")
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Embargo was successfully updated' }
      end
    end
  end
  def datastream_update
    
    req_params=['id','dsid','content']
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
  def save_crop
    @druid = params[:id].sub(/^druid:/,'')
    @image_data = JSON.parse(request.body.read)
    @image_data.each { |file_data|
      file_data.symbolize_keys!
      file_data[:cropCoords].symbolize_keys! if file_data.has_key?(:cropCoords)
      file = Legacy::File.find(file_data[:id])
      file.webcrop = file_data
    }
    render :json => @image_data.to_json
  end

  def update_attributes
    if(params[:publish].nil? || params[:publish]!='on')
      params[:publish]='no'
    else
      params[:publish]='yes'
    end
    if(params[:shelve].nil? || params[:shelve]!='on')
      params[:shelve]='no'
    else
      params[:shelve]='yes'
    end
    if(params[:preserve].nil? || params[:preserve]!='on')
      params[:preserve]='no'
    else
      params[:preserve]='yes'
    end
    @object.contentMetadata.update_attributes(params[:file_name], params[:publish], params[:shelve], params[:preserve])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Updated attributes for file '+params[:file_name]+'!' }
    end
  end
  def create_minimal_mods
    if not (Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'descriptive-metadata')=='error' or Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'publish')=='error')
      render :text => 'Object is not in error for descMD or publish!', :status => 500
      return
    end
    if not @object.descMetadata.new?
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
    begin
      @object.open_new_version
      @object.datastreams['events'].add_event("open", current_user.to_s , "Version "+ @object.versionMetadata.current_version_id.to_s + " opened")
      @object.save
      severity=params[:severity]
      desc=params[:description]
      ds=@object.versionMetadata
      ds.update_current_version({:description => desc,:significance => severity.to_sym})
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => params[:id]+' is open for modification!' }  
      end
    rescue Exception => e
      if e.to_s == 'Object net yet accessioned'
        render :status=> 500, :text =>'Object net yet accessioned'
        return
      else
        raise e
      end
    end
  end
  def close_version
    severity=params[:severity]
    desc=params[:description]
    ds=@object.versionMetadata
    ds.update_current_version({:description => desc,:significance => severity.to_sym})
    @object.save
    Dor::WorkflowService.configure  Argo::Config.urls.workflow, :dor_services_url => Argo::Config.urls.dor_services
    @object.close_version
    @object.datastreams['events'].add_event("close", current_user.to_s , "Version "+ @object.versionMetadata.current_version_id.to_s + " closed")
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Version '+@object.current_version+' of '+params[:id]+' has been closed!' }  
    end
  end
  def source_id
    new_id=params[:new_id].strip
    @object.set_source_id(new_id)
    @object.identityMetadata.dirty=true
    respond_to do |format|
      if params[:bulk]
        render :status => 200, :text =>'Updated source id.'
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
    @object.identityMetadata.dirty=true
    @object.identityMetadata.save
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Tags for '+params[:id]+' have been updated!' }  
    end
  end
  def tags
    current_tags=@object.tags
    if params[:add]
      if params[:new_tag1] and params[:new_tag1].length > 0
        @object.add_tag(params[:new_tag1])
      end
      if params[:new_tag2] and params[:new_tag2].length > 0 
        @object.add_tag(params[:new_tag2])
      end
      if params[:new_tag3]  and params[:new_tag3].length > 0
        @object.add_tag(params[:new_tag3])
      end
    end
    if params[:del]
      if not @object.remove_tag(current_tags[params[:tag].to_i - 1])
        raise 'failed to delete'
      end
    end
    if params[:update]
      count = 1
      current_tags.each do |tag|
        @object.update_tag(tag,params[('tag'+count.to_s).to_sym])
        count+=1
      end
    end
    @object.identityMetadata.dirty=true
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
      if not forbid_modify
        return 
      end
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
    if params[:position]
      @object.move_resource(params[:resource], params[:position])
    end
    if params[:label]
      @object.update_resource_label(params[:resource], params[:label])
    end
    if params[:type]
      @object.update_resource_type(params[:resource], params[:type])
    end
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'updated resource ' + params[:resource] + '!' }  
    end
  end
  def discoverable
    messages=mods_discoverabable @object.descMetadata.ng_xml
    if messages.length == 0
      render :status => :ok, :text => 'Discoverable.'
    else
      msgs=''
      messages.each do |msg|
        msgs+=msg
      end
      render :status => 500, :text => msgs
    end
  end
  def remove_duplicate_encoding
    ds=params[:ds]
    content=ds.content
    old_content=content
    content=CGI.unescape_html(content)
    ng=Nokogiri::XML(content,nil,'UTF-8')
    ds.ng_xml=ng
    ds.content=ng.to_s
    ds.save
  end
  def remediate_mods
    ds=@object.descMetadata
    content=ds.content
    mclaughlin_remediation ds.ng_xml
    ds.content=ds.ng_xml.to_s
    ds.save
    render :status => :ok, :text => 'No change'
  end
  def schema_validation
    ds=@object.descMetadata
    content=ds.content
    errors= schema_validate ds.ng_xml
    if errors.length == 0
      render :status => :ok, :text => 'Valid.'
    else
      error_str=''
      errors.each do |er|
        error_str+=er+'<br>'
      end
      render :status => 500, :text => error_str[0...490] 
    end
  end
  def refresh_metadata
    @object.build_datastream('descMetadata',true)
    @object.descMetadata.content = @object.descMetadata.ng_xml.to_s
    @object.descMetadata.save
    render :status => :ok, :text => 'Refreshed.'
  end

  def detect_duplicate_encoding
    ds=@object.descMetadata
    content=ds.content
    /&amp;#[0-9]+;/
    chars=['amp', 'lt', 'gt','quot']
    regexes=["#[0-9]+","#x[0-9A-Fa-f]+"]
    chars.each do |char|
      content=content.gsub('&amp;'+char+';', '&'+char+';')
    end
    content=content.gsub /&amp;(\#[0-9]+;)/, '&\1' 
    content=content.gsub /&amp;(\#x[0-9A-Fa-f];)/, '&\1' 
    ng=Nokogiri::XML(content,nil,'UTF-8')
    if EquivalentXml.equivalent?(ng,ds.ng_xml)
      render :status => :ok, :text => 'No change'
    else
      render :status => 500, :text => 'Has duplicates'
    end
  end
  def change_mods_value
    mods=Mods::Reader.new(@object.descMetadata.content)
    params[:field]
    if mods.methods.include? params[:field].to_sym
      mods.send(params[:field].to_sym, params[:val])
    end
  end
  def remove_duplicate_encoding
    ds=@object.descMetadata
    content=ds.content
    /&amp;#[0-9]+;/
    chars=['amp', 'lt', 'gt','quot']
    regexes=["#[0-9]+","#x[0-9A-Fa-f]+"]
    chars.each do |char|
      content=content.gsub('&amp;'+char+';', '&'+char+';')
    end
    content=content.gsub /&amp;(\#[0-9]+;)/, '&\1' 
    content=content.gsub /&amp;(\#x[0-9A-Fa-f];)/, '&\1' 
    ng=Nokogiri::XML(content,nil,'UTF-8')
    if EquivalentXml.equivalent?(ng,ds.ng_xml)
      render :status => 500, :text => 'No duplicate encoding'
      return
    else
      ds.ng_xml=ng
      ds.content=ng.to_s
      @object.save
      render :status => :ok, :text => 'Has duplicates'
    end
  end
  def set_rights
    if not ['stanford','world', 'none', 'dark'].include? params[:rights]
      render :status=> :forbidden, :text =>'Invalid new rights setting.'
      return
    end
    @object.set_read_rights(params[:rights])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Rights updated!' }  
    end
  end
  #set the content type in the content metadata
  def set_content_type
    if not ['book', 'file', 'image','map','manuscript'].include? params[:new_content_type]
      render :status=> :forbidden, :text =>'Invalid new content type.'
      return
    end
    if not @object.datastreams.include? 'contentMetadata'
      render :status=> :forbidden, :text =>'Object doesnt have a content metadata datastream to update.'
      return
    end
    @object.contentMetadata.set_content_type(params[:old_content_type], params[:old_resource_type], params[:new_content_type], params[:new_resource_type])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Content type updated!' }  
    end
  end

  #if an item errored in sdr-ingest-transfer due to missing provenance metadata, create the datastream and reset the error
  def fix_missing_provenance
    if Dor::WorkflowService.get_workflow_status('dor', @object.id, 'accessionWF', 'sdr-ingest-transfer') =='error' and @object.provenanceMetadata.new?
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
  
  #set the workflow priority for an object
  def prioritize
    updated=false
    @object.workflows.workflows.each do |wf|
      workflow=wf.workflowId.first
      wf.processes.each do |proc|
        if not proc.completed? and not proc.version and not proc.priority.to_i > 0
          Dor::WorkflowService.update_workflow_status(wf.repository.first, @object.id, workflow , proc.name, proc.status, {:priority => 50} )
          updated=true
        end
      end
    end 
    if updated
      render :status=> 200, :text =>'Expedited.'
    else
      render :status=> 500, :text =>'No processes eligable for expedite.'
    end
  end
  #add a workflow to an object if the workflow is not present in the active table
  def add_workflow
    if params[:wf]
      wf = @object.workflows[params[:wf]]

        
        #check for this workflow is present and active (not archived)
        if wf and wf.active?
          render :status => 500, :text => "#{params[:wf]} already exists!"
          return
        end
        @object.initialize_workflow(params[:wf])
        if params[:bulk]
          puts 'redirect'
          
          render :text => "Added #{params[:wf]}"
        else
          redirect_to catalog_path(params[:id]), :notice => "Added #{params[:wf]}" 
        end
      end
    
  end
  
  private 
  def reindex item
    doc=item.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end
  def create_obj
    if params[:id]
      begin
        @object = Dor::Item.find params[:id]
        @apo=@object.admin_policy_object
        if @apo
          @apo=@apo.pid
        else
          @apo=''
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        render :status=> 500, :text =>'Object doesnt exist in Fedora.'
        return
      end
    else
      raise 'missing druid'
    end
  end
  def save_and_reindex
    @object.save
    reindex @object unless(params[:bulk])
  end

  #check that the user can carry out this item modification
  def forbid_modify
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles @apo)
      render :status=> :forbidden, :text =>'forbidden'
      return false
    end
    true
  end
  def forbid_view
    if not current_user.is_admin and not @object.can_view_content?(current_user.roles @apo)
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
  end
  def enforce_versioning
    #if this object has been submitted, doesnt have an open version, and isnt sitting at sdr-ingest with a hold, they cannot change it.
    if not @object.allows_modification? and not on_hold
      render :status=> :forbidden, :text =>'Object cannot be modified in its current state.'
      return
    end
  end
end
