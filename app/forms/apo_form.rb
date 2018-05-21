# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
class ApoForm < BaseForm
  attr_reader :default_collection_pid
  # @param [HashWithIndifferentAccess] params the parameters from the form
  # @return [Boolean] true if the parameters are valid
  def validate(params)
    @params = param_cleanup(params)

    # error if title is empty
    errors.push(:title) if @params[:title].blank?

    # error if managers or viewers role list is invalid
    [:managers, :viewers].each do |roleplayer_list|
      next unless @params[roleplayer_list]
      next if valid_role_list?(split_roleplayer_input_field(@params[roleplayer_list]))
      @errors.push(roleplayer_list)
    end

    @errors.push(:collection_radio) if @params[:collection_radio] == 'select' && new_record?

    @errors.empty?
  end

  # Copies the values to the model and saves and indexes
  def save
    find_or_register_model
    sync
    model.save
    model.update_index
    add_default_collection
  end

  # Copies the values to the model
  def sync
    model.mods_title           = params[:title]
    model.desc_metadata_format = params[:desc_md]
    model.metadata_source      = params[:metadata_source]
    model.agreement            = params[:agreement]
    model.default_workflow     = params[:workflow]
    model.default_rights       = params[:default_object_rights]
    # Set the Use License given a machine-readable code for a creative commons
    # or open data commons license
    model.use_license          = params[:use_license]
    model.copyright_statement  = params[:copyright]
    model.use_statement        = params[:use]

    model.add_tag(params[:tag]) if params[:tag]

    sync_roles
  end

  private

  def sync_roles
    model.purge_roles
    # and populate it with the correct roleMetadata
    if params[:managers]
      managers = split_roleplayer_input_field(params[:managers])
      add_roleplayers(managers, 'dor-apo-manager')
    end

    return unless params[:viewers]
    viewers = split_roleplayer_input_field(params[:viewers])
    add_roleplayers(viewers, 'dor-apo-viewer')
  end

  def add_default_collection
    @default_collection_pid = if params[:collection_radio] == 'create'
                                create_collection model.pid
                              elsif params[:collection]
                                params[:collection]
                              end

    model.add_default_collection(@default_collection_pid) if @default_collection_pid
  end

  def find_or_register_model
    return model if model
    @model = register_model
  end

  # @return [Dor::AdminPolicyObject] registers the APO
  def register_model
    response = Dor::RegistrationService.create_from_request(register_params)
    # Once it's been created we populate it with its metadata
    Dor.find(response[:pid])
  end

  # @return [Hash] the parameters used to register an apo. Must be called after `validate`
  def register_params
    {
      workflow_priority: '70',
      label: params[:title],
      object_type: 'adminPolicy',
      admin_policy: SolrDocument::UBER_APO_ID,
      workflow_id: 'accessionWF'
    }
  end

  def param_cleanup(params)
    params[:title].strip! if params[:title]
    [:managers, :viewers].each do |role_param_sym|
      params[role_param_sym] = params[role_param_sym].tr("\n,", ' ') if params[role_param_sym]
    end
    params
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

  def split_roleplayer_input_field(roleplayer_list_str)
    roleplayer_list_str.split(/[,\s]/).reject(&:empty?)
  end

  def add_roleplayers(roleplayer_list, role)
    roleplayer_list.each do |roleplayer|
      model.add_roleplayer role, roleplayer
    end
  end

  # Create a collection
  # @param [String] apo_pid the identifier for this APO
  # @return [String] the pid for the newly created collection
  def create_collection(apo_pid)
    form = CollectionForm.new
    form.validate(params.merge(apo_pid: apo_pid))
    form.save
    form.model.id
  end
end
