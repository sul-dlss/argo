class ItemsController < ApplicationController
  before_filter :authorize!
  helper DorObjectHelper  
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
  
  def register
    @perm_keys = ["sunetid:#{current_user.login}"] 
    if webauth and webauth.privgroup.present?
      @perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end
    render :register, :layout => 'application'
  end
  
  def is_admin?
  if @perm_keys==nil
    @perm_keys = ["sunetid:#{current_user.login}"] 
      if webauth and webauth.privgroup.present?
        @perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
      end
  end
  	@perm_keys.each do |key|
  		if key == 'workgroup:dlss:lyberteam'
  		return true
  		end
  	end
  	return false
  end
  def workflow_view
    @obj = Dor.find params[:id], :lightweight => true
    @workflow_id = params[:wf_name]
    @workflow = @workflow_id == 'workflow' ? @obj.workflows : @obj.workflows[@workflow_id]

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
   def embargo_update
      if not is_admin?
      	render :status=> :forbidden, :text =>'forbidden'
      else
			  @item = Dor.find params[:id]
      	new_date=DateTime.parse(params[:embargo_date])
		  	@item.update_embargo(new_date)
      	begin
        	@item.update_index
      	rescue Exception => e
        	Rails.logger.warn "ItemsController#embargo_update failed to update solr index for #{@item.pid}: #<#{e.class.name}: #{e.message}>"
    		end
      	respond_to do |format|
        format.any { redirect_to catalog_path(@item.pid), :notice => 'Embargo was successfully updated' }
      end
	end
  end
  def workflow_update
    args = params.values_at(:id, :wf_name, :process, :status)
    if args.all? &:present?
      Dor::WorkflowService.update_workflow_status 'dor', *args
      @item = Dor.find params[:id]
      begin
        @item.update_index
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
  def datastream_update
  	if not is_admin?
    	render :status=> :forbidden, :text =>'forbidden'
 			return   
    else
    	req_params=['id','dsid','content']
    	item = Dor.find params[:id]
    	ds=item.datastreams[params[:dsid]]
    	#check that the content is valid xml
    	begin
    		content=Nokogiri::XML(params[:content]){ |config| config.strict }
    	rescue
    		raise 'XML was not well formed!'
    	end
    	ds.content=content.to_s
    	puts ds.content
    	ds.save
    	if ds.dirty?
    		raise 'datastream didnt write'
    	end
    	respond_to do |format|
        format.any { redirect_to ds_aspect_view_catalog_path(params[:id], params[:dsid]), :notice => 'Datastream was successfully updated' }
      end
    end
  end
end
