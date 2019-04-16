# frozen_string_literal: true

# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
class ApoForm < BaseForm
  DEFAULT_MANAGER_WORKGROUPS = %w(developer service-manager metadata-staff).freeze

  attr_reader :default_collection_pid

  # @param [HashWithIndifferentAccess] params the parameters from the form
  # @return [Boolean] true if the parameters are valid
  def validate(params)
    @params = param_cleanup(params)

    # error if title is empty
    errors.push(:title) if @params[:title].blank?

    @errors.push(:collection_radio) if @params[:collection_radio] == 'select' && new_record?

    @errors.empty?
  end

  # Copies the values to the model and saves and indexes
  def save
    find_or_register_model
    sync
    add_default_collection
    model.save
    model.update_index
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

    Dor::TagService.add(model, params[:tag]) if params[:tag]

    sync_roles
  end

  # @return [Array<Hash>] the list of permissions (grants for users/groups) on this object
  def permissions
    return default_permissions if new_record?

    manage_permissions + view_permissions
  end

  def default_workflow
    return Settings.apo.default_workflow_option if new_record?

    model.administrativeMetadata.ng_xml.xpath('//registration/workflow/@id').to_s
  end

  def use_license
    return '' if new_record?

    model.use_license
  end

  def default_rights
    return 'world' if new_record?

    model.default_rights
  end

  def desc_metadata_format
    return 'MODS' if new_record?

    model.desc_metadata_format
  end

  def metadata_source
    return 'DOR' if new_record?

    model.metadata_source
  end

  def use_statement
    return if new_record?

    model.use_statement
  end

  def copyright_statement
    return if new_record?

    model.copyright_statement
  end

  def mods_title
    return '' if new_record?

    model.mods_title
  end

  def default_collection_objects
    return [] if new_record?

    @default_collection_objects ||= begin
      Array(model.default_collections).map { |pid| Dor.find(pid) }
    end
  end

  def to_param
    return nil if new_record?

    model.pid
  end

  def license_options
    cur_use_license = model ? model.use_license : nil
    [['-- none --', '']] +
      options_for_use_license_type(CreativeCommonsLicenseService, cur_use_license) +
      options_for_use_license_type(OpenDataLicenseService, cur_use_license)
  end

  private

  # return a list of lists, where the sublists are pairs, with the first element being the text to display
  # in the selectbox, and the second being the value to submit for the entry.  include only non-deprecated
  # entries, unless the current value is a deprecated entry, in which case, include that entry with the
  # deprecation warning in a parenthetical.
  def options_for_use_license_type(license_service, current_value)
    license_service.options do |term|
      if term.key == current_value && term.deprecation_warning
        ["#{term.label} (#{term.deprecation_warning})", term.key]
      elsif term.deprecation_warning.nil?
        [term.label, term.key]
      end
    end.compact # the options block will produce nils for unused deprecated entries, compact will get rid of them
  end

  def manage_permissions
    build_permissions(Array(model.roles['dor-apo-manager']), 'manage')
  end

  def view_permissions
    build_permissions(Array(model.roles['dor-apo-viewer']), 'view')
  end

  def build_permissions(role_list, access)
    role_list.map do |name|
      if name.starts_with? 'workgroup:'
        { name: name.sub(/^workgroup:[^:]*:/, ''), type: 'group', access: access }
      else
        { name: name.sub(/^sunetid:/, ''), type: 'person', access: access }
      end
    end
  end

  def default_permissions
    DEFAULT_MANAGER_WORKGROUPS.map do |name|
      { name: name, type: 'group', access: 'manage' }
    end
  end

  def sync_roles
    model.purge_roles
    return unless params[:permissions]

    # and populate it with the correct roleMetadata
    attributes = params[:permissions].values
    attributes.each do |perm|
      if perm[:access] == 'manage'
        model.add_roleplayer('dor-apo-manager', "sdr:#{perm[:name]}")
      elsif perm[:access] == 'view'
        model.add_roleplayer('dor-apo-viewer', "sdr:#{perm[:name]}")
      end
    end
  end

  # Adds a new or existing collection as the default collection for the APO
  def add_default_collection
    @default_collection_pid = if params[:collection_radio] == 'create'
                                create_collection model.pid
                              elsif params[:collection].present? # Guards against empty string
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
    response = Dor::Services::Client.objects.register(params: register_params)
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
    params[:title]&.strip!
    [:managers, :viewers].each do |role_param_sym|
      params[role_param_sym] = params[role_param_sym].tr("\n,", ' ') if params[role_param_sym]
    end
    params
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
