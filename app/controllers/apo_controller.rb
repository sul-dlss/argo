require 'rest-client'

class ApoController < ApplicationController

  before_filter :create_obj, :except => [:register, :is_valid_role_list_endpoint, :spreadsheet_template]
  after_filter :save_and_index, :only => [:delete_collection, :delete_collection, :add_collection, :update_title, :update_creative_commons, :update_use, :update_copyright, :update_default_object_rights, :add_roleplayer, :update_desc_metadata, :delete_role, :register_collection]

  DEFAULT_MANAGER_WORKGROUPS = ['sdr:developer', 'sdr:service-manager', 'sdr:metadata-staff']

  @@cc = {
    'by' => 'Attribution 3.0 Unported',
    'by_sa' => 'Attribution Share Alike 3.0 Unported',      # this has got to be wrong when everything else is hyphenated!
    'by-nd' => 'Attribution No Derivatives 3.0 Unported',
    'by-nc' => 'Attribution Non-Commercial 3.0 Unported',
    'by-nc-sa' => 'Attribution Non-Commercial Share Alike 3.0 Unported',
    'by-nc-nd' => 'Attribution Non-commercial, No Derivatives 3.0 Unported',
  }

  def is_valid_role_name role_name
    return /^[\w-]+:[\w-]+$/.match(role_name) != nil
  end

  def is_valid_role_list role_list
    # look for an invalid role name, return true if we don't find one
    return role_list.find { |role_name| !is_valid_role_name(role_name) } == nil
  end

  def is_valid_role_list_endpoint
    # this should only get one of the params at a time
    role_list_str = params[:managers] || params[:viewers] || params[:role_list] || nil
    if !role_list_str
      ret_val = false
    else
      ret_val = is_valid_role_list(split_roleplayer_input_field(role_list_str))
    end

    respond_to do |format|
      format.json {
        render :json => ret_val
      }
    end
  end

  def get_input_params_errors input_params
    # assume no errors yet
    err_list = []

    # error if title is empty
    if input_params[:title].strip.length == 0
      err_list.push(:title)
    end

    # error if managers or viewers role list is invalid
    [:managers, :viewers].each do |roleplayer_list|
      if !is_valid_role_list(split_roleplayer_input_field(input_params[roleplayer_list]))
        err_list.push(roleplayer_list)
      end
    end

    return err_list
  end

  def register
    param_cleanup params

    if params[:title]
      input_params_errors = get_input_params_errors params
      if input_params_errors.length > 0
        render :status=> :bad_request, :json => { :errors => input_params_errors }
        return
      end

      apo_info = register_new_apo
      respond_to do |format|
        format.any { redirect_to catalog_path(apo_info[:apo_pid]), :notice => apo_info[:notice] }
      end
    elsif params[:id]
      create_obj
      @managers=[]
      @viewers=[]
      populate_role_form_field_var(@object.roles['dor-apo-manager'], @managers)
      populate_role_form_field_var(@object.roles['dor-apo-viewer'], @viewers)
      @cur_default_workflow = @object.administrativeMetadata.ng_xml.xpath('//registration/workflow/@id').to_s
    end
  end

  def set_apo_metadata apo, md_info
    apo.copyright_statement = md_info[:copyright] if md_info[:copyright] && md_info[:copyright].length > 0
    apo.use_statement = md_info[:use] if md_info[:use] && md_info[:use].length > 0
    apo.mods_title = md_info[:title]
    apo.desc_metadata_format = md_info[:desc_md]
    apo.metadata_source = md_info[:metadata_source]
    apo.agreement = md_info[:agreement].to_s
    apo.default_workflow = md_info[:workflow] unless (not md_info[:workflow] || md_info[:workflow].length < 5)
    apo.creative_commons_license = md_info[:cc_license]
    apo.creative_commons_license_human = @@cc[md_info[:cc_license]]
    apo.default_rights = md_info[:default_object_rights]
  end

  def register_new_apo
    reg_params = {:workflow_priority => '70'}
    reg_params[:label] = params[:title]
    reg_params[:object_type ] = 'adminPolicy'
    reg_params[:admin_policy] = 'druid:hv992ry2431'
    reg_params[:workflow_id ] = 'accessionWF'
    response = Dor::RegistrationService.create_from_request(reg_params)
    apo_pid = response[:pid]
    apo = Dor.find(apo_pid)

    #register a collection if requested
    collection_pid = nil
    if params[:collection_radio] == 'create'
      collection_pid = create_collection apo_pid
    end
    if collection_pid
      apo.add_default_collection collection_pid
    else
      if params[:collection] && params[:collection].length > 0
        apo.add_default_collection params[:collection]
      end
    end

    set_apo_metadata apo, params
    apo.add_tag('Registered By : ' + current_user.login)

    managers = split_roleplayer_input_field(params[:managers])
    viewers = split_roleplayer_input_field(params[:viewers])
    add_roleplayers_to_object(apo, managers, 'dor-apo-manager')
    add_roleplayers_to_object(apo, viewers, 'dor-apo-viewer')

    apo.save
    update_index(apo)
    notice = 'APO created. '
    if collection_pid
      notice += "Collection #{collection_pid} created."
    end
    return {:notice => notice, :apo_pid => apo_pid, :collection_pid => collection_pid}
  end

  def param_cleanup params
    params[:title].strip! unless not params[:title]
    [:managers, :viewers].each do |role_param_sym|
      params[role_param_sym] = params[role_param_sym].gsub('\n',' ').gsub(',',' ') unless not params[role_param_sym]
    end
  end

  # wrapper around call to update_index for various objects (APO, collection, item)
  # provides easily-stubbed method for testing (instead of all object types)
  def update_index(obj)
    obj.update_index
  end

  def update
    param_cleanup params
    input_params_errors = get_input_params_errors params
    if input_params_errors.length > 0
      render :status=> :bad_request, :json => { :errors => input_params_errors }
      return
    end

    if params[:collection_radio] == 'create'
      collection_pid = create_collection @object.pid
    end
    if params[:collection] && params[:collection].length > 0
      @object.add_default_collection params[:collection]
    else
      if collection_pid
        @object.add_default_collection collection_pid
      end
    end

    set_apo_metadata @object, params

    @object.purge_roles
    managers = split_roleplayer_input_field(params[:managers])
    viewers = split_roleplayer_input_field(params[:viewers])
    add_roleplayers_to_object(@object, managers, 'dor-apo-manager')
    add_roleplayers_to_object(@object, viewers, 'dor-apo-viewer')

    @object.save
    update_index(@object)
    redirect
  end

  def register_collection
    if params[:collection_title] or params[:collection_catkey]
      collection_pid = create_collection params[:id], 'label'
      @object.add_default_collection collection_pid
      redirect_to catalog_path(params[:id]), :notice => "Created collection #{collection_pid}"
    end
  end

  def create_collection apo_pid, metadata_source_init_value=nil
    reg_params = {:workflow_priority => '65'}
    if params[:collection_title] && params[:collection_title].length > 0
      reg_params[:label] = params[:collection_title]
    else
      reg_params[:label] = ':auto'
    end
    if reg_params[:label] == ':auto'
      reg_params[:rights] = params[:collection_rights_catkey]
    else
      reg_params[:rights] = params[:collection_rights]
    end
    if reg_params[:rights]
      reg_params[:rights] = reg_params[:rights].downcase
    end
    reg_params[:object_type] = 'collection'
    reg_params[:admin_policy] = apo_pid
    reg_params[:metadata_source] = metadata_source_init_value if metadata_source_init_value
    reg_params[:metadata_source] = 'symphony' if params[:collection_catkey] && params[:collection_catkey].length > 0
    reg_params[:other_id] = 'symphony:' + params[:collection_catkey] if params[:collection_catkey] && params[:collection_catkey].length > 0
    reg_params[:metadata_source] = 'label' unless params[:collection_catkey] && params[:collection_catkey].length > 0
    reg_params[:workflow_id] = 'accessionWF'
    response = Dor::RegistrationService.create_from_request(reg_params)
    collection_pid = response[:pid]
    collection = Dor.find(collection_pid)
    if params[:collection_abstract] && params[:collection_abstract].length > 0
      set_abstract(collection, params[:collection_abstract])
    end
    collection.save
    update_index(collection)
    return collection_pid
  end

  def add_roleplayer
    @object.add_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_role
    @object.delete_role(params[:role], params[:roleplayer])
    redirect
  end

  def delete_collection
    @object.remove_default_collection(params[:collection])
    redirect
  end

  def add_collection
    @object.add_default_collection(params[:collection])
    redirect
  end

  def update_title
    @object.mods_title = params[:title]
    redirect
  end

  def update_creative_commons
    @object.creative_commons_license = params[:creative_commons]
    @object.creative_commons_license_human = @@cc[params[:creative_commons]]
    redirect
  end

  def update_use
    @object.use_statement = params[:use]
    redirect
  end

  def update_copyright
    @object.copyright_statement = params[:copyright]
    redirect
  end

  def update_default_object_rights
    @object.default_rights = params[:rights]
    redirect
  end

  def update_desc_metadata
    @object.desc_metadata_format = params[:desc_metadata_format]
    redirect
  end

  def bulk_upload_start
    @object = Dor.find params[:id]
  end

  def bulk_upload_form
    @object = Dor.find params[:id]
  end

  def spreadsheet_template
    binary_string = RestClient.get("http://localhost:9292/v1/spreadsheet")
    send_data(binary_string, :filename => "spreadsheet_template.xlsx", :type =>  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  end

  def upload
    uploaded_file = params[:spreadsheet_file].tempfile

    if(params[:filetypes] == "xml")
      response_xml = RestClient.post(Argo::Config.urls.normalizer, :file => File.new(uploaded_file, 'rb'), :filename => params[:spreadsheet_file].original_filename)
      send_data(response_xml, :filename => "#{params[:id]}.xml", :type => "application/xml")
    else # spreadsheet
      if(params.has_key?(:xml_only))
        response_xml = RestClient.post(Argo::Config.urls.modsulator, :file => File.new(uploaded_file, 'rb'), :filename => params[:spreadsheet_file].original_filename)
        send_data(response_xml, :filename => "#{params[:id]}.xml", :type => "application/xml")
      else
        response_xml = RestClient.post(Argo::Config.urls.modsulator, :file => File.new(uploaded_file, 'rb'), :filename => params[:spreadsheet_file].original_filename)
        send_data(response_xml, :filename => "#{params[:id]}.xml", :type => "application/xml")
      end
    end
  end


  private

  def reindex obj
    doc=obj.to_solr
    Dor::SearchService.solr.add(doc, :add_attributes => {:commitWithin => 1000})
  end

  def create_obj
    if params[:id]
      @object = Dor.find params[:id], :lightweight => true
      @collections = @object.default_collections
      new_col=[]
      if @collections
        @collections.each do |col|
          new_col << Dor.find(col)
        end
      end
      @collections=new_col
    else
      raise 'missing druid'
    end
  end

  def add_roleplayers_to_object(object, roleplayer_list, role)
    roleplayer_list.each do |roleplayer|
      if roleplayer.include? 'sunetid'
        object.add_roleplayer role, roleplayer, 'person'
      else
        object.add_roleplayer role, roleplayer
      end
    end
  end

  def populate_role_form_field_var(role_list, form_field_var)
    if role_list
      role_list.each do |entity|
        form_field_var << entity.gsub('workgroup:', '').gsub('person:', '')
      end
    end
  end

  def split_roleplayer_input_field(roleplayer_list_str)
    return roleplayer_list_str.split(/[,\s]/).reject(){|str| str.empty?}
  end

  def save_and_reindex
    @object.save
  end

  def save_and_index
    @object.save
  end

  def redirect
    respond_to do |format|
      format.any { redirect_to catalog_path(params[:id]), :notice => 'APO updated.' }
    end
  end

  #check that the user can carry out this object modification
  def forbid
    if not current_user.is_admin and not @object.can_manage_content?(current_user.roles params[:id])
      render :status=> :forbidden, :text =>'forbidden'
      return
    end
  end

  def set_abstract collection_obj, abstract
    collection_obj.descMetadata.abstract = abstract
    collection_obj.descMetadata.content = collection_obj.descMetadata.ng_xml.to_s
    collection_obj.descMetadata.save
  end
end
