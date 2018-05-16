class ApoController < ApplicationController
  before_action :create_obj, except: [
    :is_valid_role_list_endpoint,
    :register,
    :spreadsheet_template
  ]
  after_action :save_and_index, only: [
    :add_roleplayer,
    :add_collection, :delete_collection,
    :update_copyright, :update_creative_commons,
    :update_default_object_rights, :update_desc_metadata,
    :update_title, :update_use,
    :delete_role,
    :register_collection
  ]

  before_action :authorize, except: [
    :is_valid_role_list_endpoint,
    :register,
    :spreadsheet_template
  ]

  DEFAULT_MANAGER_WORKGROUPS = %w(sdr:developer sdr:service-manager sdr:metadata-staff).freeze

  # This action is used by the javascript that sends results as the user enters
  # them on the form to determine if the user supplied input is valid.
  def is_valid_role_list_endpoint
    # Only checks the first found relevant param
    role_list_str = params[:managers] || params[:viewers] || params[:role_list] || nil
    ret_val = if !role_list_str
                false
              else
                valid_role_list?(split_roleplayer_input_field(role_list_str))
              end

    respond_to do |format|
      format.json do
        render json: ret_val
      end
    end
  end

  def register
    authorize! :create, Dor::AdminPolicyObject

    param_cleanup params

    if params[:title]
      input_params_errors = get_input_params_errors params
      if input_params_errors.length > 0
        render status: :bad_request, json: { errors: input_params_errors }
        return
      end

      apo_info = register_new_apo
      respond_to do |format|
        format.any { redirect_to solr_document_path(apo_info[:apo_pid]), notice: apo_info[:notice] }
      end
    elsif params[:id]
      create_obj
      @managers = []
      @viewers  = []
      populate_role_form_field_var(@object.roles['dor-apo-manager'], @managers)
      populate_role_form_field_var(@object.roles['dor-apo-viewer'], @viewers)
      @cur_default_workflow = @object.administrativeMetadata.ng_xml.xpath('//registration/workflow/@id').to_s
      render layout: 'blacklight'
    else
      render layout: 'blacklight'
    end
  end

  # TODO: spec testing requires this method to be public
  def set_apo_metadata(apo, md_info)
    apo.mods_title           = md_info[:title]
    apo.desc_metadata_format = md_info[:desc_md]
    apo.metadata_source      = md_info[:metadata_source]
    apo.agreement            = md_info[:agreement]
    apo.default_workflow     = md_info[:workflow]
    apo.default_rights       = md_info[:default_object_rights]
    # Set the Use License given a machine-readable code for a creative commons
    # or open data commons license
    apo.use_license          = md_info[:use_license]
    apo.copyright_statement  = md_info[:copyright]
    apo.use_statement        = md_info[:use]
  end

  ##
  # Register a new APO and a create a default collection if requested.
  # Uses `params` and `Dor::RegistrationService`
  #
  def register_new_apo
    reg_params = { workflow_priority: '70' }
    reg_params[:label] = params[:title]
    reg_params[:object_type] = 'adminPolicy'
    reg_params[:admin_policy] = SolrDocument::UBER_APO_ID
    reg_params[:workflow_id] = 'accessionWF'
    response = Dor::RegistrationService.create_from_request(reg_params)
    apo_pid = response[:pid]
    notice = "APO #{apo_pid} created."

    # Once it's been created we populate it with its metadata
    apo = Dor.find(apo_pid)
    set_apo_metadata apo, params
    apo.add_tag('Registered By : ' + current_user.login)

    # and populate it with the correct roleMetadata
    managers = split_roleplayer_input_field(params[:managers])
    viewers  = split_roleplayer_input_field(params[:viewers])
    add_roleplayers_to_object(apo, managers, 'dor-apo-manager')
    add_roleplayers_to_object(apo, viewers, 'dor-apo-viewer')

    # requires a synchronous index update as we will redirect to the show page
    apo.save
    update_index(apo)

    # register a collection and make it the default if requested
    collection_pid = nil
    case params[:collection_radio]
    when 'create'
      collection_pid = create_collection apo_pid
      apo.add_default_collection collection_pid
      apo.save
      notice += " Collection #{collection_pid} created."
    when 'select'
      notice += ' Cannot select a default collection when registering an APO. Use Edit APO instead.'
    end

    { notice: notice, apo_pid: apo_pid, collection_pid: collection_pid }
  end

  def param_cleanup(params)
    params[:title].strip! if params[:title]
    [:managers, :viewers].each do |role_param_sym|
      params[role_param_sym] = params[role_param_sym].gsub('\n', ' ').gsub(',', ' ') if params[role_param_sym]
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
      render status: :bad_request, json: { errors: input_params_errors }
      return
    end

    set_apo_metadata @object, params

    @object.purge_roles
    managers = split_roleplayer_input_field(params[:managers])
    viewers  = split_roleplayer_input_field(params[:viewers])
    add_roleplayers_to_object(@object, managers, 'dor-apo-manager')
    add_roleplayers_to_object(@object, viewers, 'dor-apo-viewer')

    @object.save
    update_index(@object) # TODO: does this really require a synchronous index update?

    collection_pid = create_collection @object.pid if params[:collection_radio] == 'create'
    if params[:collection] && params[:collection].length > 0
      @object.add_default_collection params[:collection]
    elsif collection_pid
      @object.add_default_collection collection_pid
    end

    redirect
  end

  def create_collection(apo_pid)
    reg_params = { workflow_priority: '65' }
    reg_params[:label] = if !params[:collection_title].blank?
                           params[:collection_title]
                         else
                           ':auto'
                         end
    reg_params[:rights] = if reg_params[:label] == ':auto'
                            params[:collection_rights_catkey]
                          else
                            params[:collection_rights]
                          end
    reg_params[:rights] &&= reg_params[:rights].downcase
    col_catkey = params[:collection_catkey] || ''
    reg_params[:object_type] = 'collection'
    reg_params[:admin_policy] = apo_pid
    reg_params[:metadata_source] = col_catkey.blank? ? 'label' : 'symphony'
    reg_params[:other_id] = "symphony:#{col_catkey}" unless col_catkey.blank?
    reg_params[:workflow_id] = 'accessionWF'
    response = Dor::RegistrationService.create_from_request(reg_params)
    collection = Dor.find(response[:pid])
    if params[:collection_abstract] && params[:collection_abstract].length > 0
      set_abstract(collection, params[:collection_abstract])
    end
    collection.save
    update_index(collection) # TODO: does this actually require a synchronous index update?
    response[:pid]
  end

  def register_collection
    return unless params[:collection_title].present? || params[:collection_catkey].present?
    collection_pid = create_collection params[:id]
    @object.add_default_collection collection_pid
    redirect_to solr_document_path(params[:id]), notice: "Created collection #{collection_pid}"
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
    @object.creative_commons_license = params[:cc_license]
    @object.creative_commons_license_human = Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[params[:cc_license]][:human_readable]
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

  def spreadsheet_template
    binary_string = Faraday.get(Settings.SPREADSHEET_URL)
    send_data(
      binary_string.body,
      filename: 'spreadsheet_template.xlsx',
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  private

  def get_input_params_errors(input_params)
    err_list = [] # assume no errors yet

    # error if title is empty
    err_list.push(:title) if input_params[:title].strip.length == 0

    # error if managers or viewers role list is invalid
    [:managers, :viewers].each do |roleplayer_list|
      unless valid_role_list?(split_roleplayer_input_field(input_params[roleplayer_list]))
        err_list.push(roleplayer_list)
      end
    end

    err_list
  end

  # @param [String] role_name
  # @return [Boolean] true if name is valid
  def valid_role_name?(role_name)
    !/^[\w-]+:[\w-]+$/.match(role_name).nil?
  end

  # @param [Array[String]] role_list
  # @return [Boolean] true if we don't find an invalid role name
  def valid_role_list?(role_list)
    role_list.all? { |role_name| valid_role_name?(role_name) }
  end

  def create_obj
    raise 'missing druid' unless params[:id]
    @object = Dor.find params[:id]
    pids = @object.default_collections || []
    @collections = pids.map { |pid| Dor.find(pid) }
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
    return unless role_list
    role_list.each do |entity|
      form_field_var << entity.gsub('workgroup:', '').gsub('person:', '')
    end
  end

  def split_roleplayer_input_field(roleplayer_list_str)
    roleplayer_list_str.split(/[,\s]/).reject(&:empty?)
  end

  def save_and_index
    @object.save # indexing happens automatically
  end

  def redirect
    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: 'APO updated.' }
    end
  end

  def set_abstract(collection_obj, abstract)
    collection_obj.descMetadata.abstract = abstract
    collection_obj.descMetadata.content = collection_obj.descMetadata.ng_xml.to_s
    collection_obj.descMetadata.save
  end

  def authorize
    authorize! :manage_item, @object
  end
end
