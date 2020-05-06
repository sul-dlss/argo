# frozen_string_literal: true

# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
class ApoForm < BaseForm
  DEFAULT_MANAGER_WORKGROUPS = %w[developer service-manager metadata-staff].freeze

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

  # Copies the values to the model, saves and indexes, and starts workflow.
  def save
    @needs_accession_workflow = false
    find_or_register_model
    sync
    add_default_collection
    add_administrative_tags!
    model.save!
    Argo::Indexer.reindex_pid_remotely(model.pid)
    # Kick off the accessionWF after all updates are complete.
    WorkflowClientFactory.build.create_workflow_by_name(model.pid, 'accessionWF', version: '1') if @needs_accession_workflow
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

  delegate :use_license, :agreement, :use_statement, :copyright_statement,
           :default_rights, :mods_title, to: :model

  def desc_metadata_format
    model.desc_metadata_format || 'MODS'
  end

  def metadata_source
    return 'DOR' if new_record?

    model.metadata_source
  end

  def default_collection_objects
    @default_collection_objects ||= begin
      Array(model.default_collections).map { |pid| Dor.find(pid) }
    end
  end

  def to_param
    model.pid
  end

  def license_options
    [['-- none --', '']] +
      options_for_use_license_type(Dor::CreativeCommonsLicenseService, use_license) +
      options_for_use_license_type(Dor::OpenDataLicenseService, use_license)
  end

  private

  def add_administrative_tags!
    return unless params[:tag]

    tags_client.create(tags: Array(params[:tag]))
  end

  def tags_client
    Dor::Services::Client.object(model.pid).administrative_tags
  end

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
    return model unless new_record?

    @model = register_model
  end

  # @return [Dor::AdminPolicyObject] registers the APO
  def register_model
    response = Dor::Services::Client.objects.register(params: cocina_model)
    @needs_accession_workflow = true
    # Once it's been created we populate it with its metadata
    Dor.find(response.externalIdentifier)
  end

  # @return [Hash] the parameters used to register an apo. Must be called after `validate`
  def cocina_model
    Cocina::Models::RequestAdminPolicy.new(
      label: params[:title],
      version: 1,
      type: Cocina::Models::Vocab.admin_policy,
      administrative: {
        hasAdminPolicy: SolrDocument::UBER_APO_ID
      }
    )
  end

  def param_cleanup(params)
    params[:title]&.strip!
    %i[managers viewers].each do |role_param_sym|
      params[role_param_sym] = params[role_param_sym].tr("\n,", ' ') if params[role_param_sym]
    end
    params
  end

  # Create a collection
  # @param [String] apo_pid the identifier for this APO
  # @return [String] the pid for the newly created collection
  def create_collection(apo_pid)
    form = CollectionForm.new(Dor::Collection.new)
    form.validate(params.merge(apo_pid: apo_pid))
    form.save
    form.model.id
  end
end
