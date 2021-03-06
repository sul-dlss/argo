# frozen_string_literal: true

# Writes changes on an AdminPolicy to the to the dor-services-app API
class AdminPolicyChangeSetPersister # rubocop:disable Metrics/ClassLength
  # @param [Cocina::Models::AdminPolicy] model the orignal state of the model
  # @param [AdminPolicyChangeSet] change_set the values to update.
  # @return [Cocina::Models::AdminPolicy] the model with updates applied
  def self.update(model, change_set)
    new(model, change_set).update
  end

  # @param [AdminPolicyChangeSet] change_set the values to update.
  # @return [Cocina::Models::AdminPolicy] the model with updates applied
  def self.create(change_set)
    new(nil, change_set).create
  end

  def initialize(model, change_set)
    @change_set = change_set
    @model = model || model_for_registration
  end

  def model_for_registration
    Cocina::Models::RequestAdminPolicy.new(
      label: title,
      version: 1,
      type: Cocina::Models::Vocab.admin_policy,
      administrative: { hasAdminPolicy: SolrDocument::UBER_APO_ID }
    )
  end

  def new_record?
    model.is_a? Cocina::Models::RequestAdminPolicy
  end

  def update
    updated = sync

    # TODO: If update went through sdr-api, we wouldn't have to start accessioning separately.
    response = Dor::Services::Client.object(updated.externalIdentifier).update(params: updated)
    tag_registered_by(response.externalIdentifier)

    response
  end

  def create
    # We are forced to register first, so that we have a AdminPolicy to put the default collection into.
    @model = Dor::Services::Client.objects.register(params: model)

    response = update

    # Kick off the accessionWF after all updates are complete.
    WorkflowClientFactory.build.create_workflow_by_name(response.externalIdentifier, 'accessionWF', version: '1')

    response
  end

  def sync
    updated = model
    updated = updated.new(label: title)
    updated = updated_administrative(updated)
    updated_description(updated)
  end

  private

  attr_reader :model, :change_set

  delegate :use_license, :agreement_object_id, :use_statement, :copyright_statement,
           :default_rights, :title, :default_workflows, :permissions,
           :collection_radio, :collections_for_registration, :collection,
           :registered_by, to: :change_set

  def tag_registered_by(pid)
    return unless registered_by

    tags_client(pid).create(tags: ["Registered By : #{registered_by}"])
  end

  def tags_client(pid)
    Dor::Services::Client.object(pid).administrative_tags
  end

  def updated_description(updated)
    description = { title: [{ value: title }] }
    updated_description = updated.description.new(description)
    updated.new(description: updated_description)
  end

  def updated_administrative(updated)
    rights = CocinaDroAccess.from_form_value(default_rights)
    administrative = {
      referencesAgreement: agreement_object_id,
      registrationWorkflow: registration_workflow,
      collectionsForRegistration: collection_ids,
      defaultAccess: rights.value!.merge(
        license: use_license,
        copyright: copyright_statement,
        useAndReproductionStatement: use_statement
      ),
      roles: roles
    }.compact

    updated_administrative = updated.administrative.new(administrative)
    updated.new(administrative: updated_administrative)
  end

  # Rails adds a hidden item with blank on the form so that we know they wanted to
  # update the workflows, but selected none. We filter that out for persistence.
  def registration_workflow
    default_workflows.reject(&:blank?)
  end

  # Retrieves the list of existing collections from the form and makes a new collection
  # if they've selected that.
  # @returns [Array<String>] a list of collection druids for this AdminPolicy
  def collection_ids
    # Get the ids of the existing collections from the form.
    collection_ids = collections_for_registration.values.map { |elem| elem.fetch(:id) }
    if collection_radio == 'create'
      collection_ids << create_collection(model.externalIdentifier)
    elsif collection[:collection].present? # guard against empty string
      collection_ids << collection[:collection]
    end
    collection_ids
  end

  # Create a collection
  # @param [String] apo_pid the identifier for this APO
  # @return [String] the pid for the newly created collection
  def create_collection(apo_pid)
    form = CollectionForm.new
    form.validate(collection.merge(apo_pid: apo_pid))
    form.save
    form.model.externalIdentifier
  end

  # Translate the value used on the form to the value used in Cocina
  ROLE_NAME = {
    'manage' => 'dor-apo-manager',
    'view' => 'dor-apo-viewer'
  }.freeze

  def roles
    return [] unless permissions

    attributes = permissions.values
    ungrouped_perms = attributes.each_with_object({}) do |perm, grouped|
      role_name = ROLE_NAME.fetch(perm[:access])
      grouped[role_name] ||= []
      grouped[role_name] << { type: 'workgroup', identifier: "sdr:#{perm[:name]}" }
    end

    ungrouped_perms.map { |name, members| { name: name, members: members } }
  end
end
