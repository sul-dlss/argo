class ItemsController < ApplicationController
  before_filter :authorize!
  require 'net/ssh'
  require 'net/sftp'

  before_filter :create_obj, :except => [:register,:open_bulk]
  before_filter :forbid, :only => [:add_collection, :remove_collection, :purge_object, :update_rights, :set_content_type]
  after_filter :save_and_reindex, :only => [:add_collection, :remove_collection, :open_version, :close_version, :tags, :source_id, :datastream_update, :update_rights, :set_content_type]


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

  def close_version_ui
    @description = @object.datastreams['versionMetadata'].current_description
    @tag = @object.datastreams['versionMetadata'].current_tag
  end
  def add_collection
    @object.add_collection(params[:collection])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Collection successfully added' }
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
  def workflow_update
    @item=@object
    args = params.values_at(:id, :wf_name, :process, :status)
    if args.all? &:present?
      Dor::WorkflowService.update_workflow_status 'dor', *args
      @item = Dor.find params[:id]
      begin
        reindex(@item)
      rescue Exception => e
        Rails.logger.warn "ItemsController#workflow_update failed to update solr index for #{@item.pid}: #<#{e.class.name}: #{e.message}>"
      end
      respond_to do |format|
        format.any { redirect_to workflow_view_item_path(@item.pid, params[:wf_name]), :notice => 'Workflow was successfully updated' }
      end
    else
      respond_to do |format|
        format.any { render format.to_sym => 'Bad Request', :status => :bad_request }
      end
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
    if not current_user.is_admin
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
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
  end
  def get_file
    item=Dor::Item.find(params[:id])
    if not current_user.is_admin and not item.can_view_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else  
      data=item.get_file(params[:file])
      self.response.headers["Content-Type"] = "application/octet-stream" 
      self.response.headers["Content-Disposition"] = "attachment; filename="+params[:file]
      self.response.headers['Last-Modified'] = Time.now.ctime.to_s
      self.response_body = data
    end	  
  end
  def update_attributes
    item=Dor::Item.find(params[:id])
    if not current_user.is_admin and not item.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else

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
      item.contentMetadata.update_attributes(params[:file_name], params[:publish], params[:shelve], params[:preserve])
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Updated attributes for file '+params[:file_name]+'!' }
      end
    end
  end
  def replace_file
    item=Dor::Item.find(params[:id])
    if not current_user.is_admin and not item.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
      item.replace_file params[:uploaded_file],params[:file_name]
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'File '+params[:file_name]+' was replaced!' }
      end
    end
  end
  #add a file to a resource, not to be confused with add a resource to an object
  def add_file
    item=Dor::Item.find(params[:id])
    if not current_user.is_admin and not item.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
      item.add_file params[:uploaded_file],params[:resource],params[:uploaded_file].original_filename, Rack::Mime.mime_type(File.extname(params[:uploaded_file].original_filename))
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'File '+params[:uploaded_file].original_filename+' was added!' }
      end
    end
  end
  def open_version
    if not @object.can_manage_item?(current_user.roles params[:id]) and not current_user.is_admin and not current_user.is_manager
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
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
  end
  def close_version
    if not @object.can_manage_item?(current_user.roles params[:id]) and not current_user.is_admin and not current_user.is_manager
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
      severity=params[:severity]
      desc=params[:description]
      ds=@object.versionMetadata
      ds.update_current_version({:description => desc,:significance => severity.to_sym})
      @object.save
      @object.close_version
      @object.datastreams['events'].add_event("close", current_user.to_s , "Version "+ @object.versionMetadata.current_version_id.to_s + " closed")
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => 'Version '+@object.current_version+' of '+params[:id]+' has been closed!' }  
      end
    end
  end
  def source_id
    #can this go in a filter to avoid repeating myself?
    if not @object.can_manage_item?(current_user.roles params[:id]) and not current_user.is_admin and not current_user.is_manager
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
    @object.set_source_id(params[:new_id])
    @object.identityMetadata.dirty=true
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Source Id for '+params[:id]+' has been updated!' }  
    end
  end
  def tags
    if not @object.can_manage_item?(current_user.roles params[:id]) and not current_user.is_admin and not current_user.is_manager
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
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
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
      @object.remove_file(params[:file_name])
      respond_to do |format|
        format.any { redirect_to catalog_path(params[:id]), :notice => params[:file_name] + ' has been deleted!' }  
      end
    end
  end
  def resource
    if not current_user.is_admin and not item.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
      @content_ds = @object.datastreams['contentMetadata']
    end
  end
  def purge_object
    if Dor::WorkflowService.get_lifecycle('dor', pid, 'submitted')
      render :status=> :forbidden, :text =>'Cannot purge an object after it is submitted.'
      return
    end
    @object.delete
    respond_to do |format|
      format.any { redirect_to '/', :notice => params[:id] + ' has been purged!' }  
    end
  end
  def update_resource
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    else
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
  end
  def update_rights
    if not ['Stanford','World', 'None', 'Dark'].include? params[:rights]
      render :status=> :forbidden, :text =>'Invalid new rights setting.'
      return
    end
    @object.set_rights(params[:rights])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Rights updated!' }  
    end
  end
  def set_content_type
    if not ['book', 'file', 'image'].include? params[:content_type]
      render :status=> :forbidden, :text =>'Invalid new content type.'
      return
    end
    if not @object.datastreams.include? 'contentMetadata'
      render :status=> :forbidden, :text =>'Object doesnt have a content metadata datastream to update.'
      return
    end
    @object.contentMetadata.set_content_type(params[:content_type], params[:resource_type])
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'Content type updated!' }  
    end
  end
  private 
  def reindex item
    doc=item.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end
  def create_obj
    if params[:id]
      @object = Dor::Item.find params[:id], :lightweight => true
      @apo=@object.admin_policy_object
      if @apo.length>0
        @apo=@apo.first.pid
      else
        @apo=''
      end
    else
      raise 'missing druid'
    end
  end
  def save_and_reindex
    @object.save
    reindex @object
  end

  #check that the user can carry out this item modification
  def forbid
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles @apo)
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
  end
end
