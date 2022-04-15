# frozen_string_literal: true

# Writes changes on an AdminPolicy to the to the dor-services-app API
class AdminPolicyPersister # rubocop:disable Metrics/ClassLength
  # @param [Cocina::Models::AdminPolicy] model the orignal state of the model
  # @param [ApoForm] form the values to update.
  # @return [Cocina::Models::AdminPolicy] the model with updates applied
  def self.update(model, form)
    new(model, form).update
  end

  # @param [ApoForm] form the values to update.
  # @return [Cocina::Models::AdminPolicy] the model with updates applied
  def self.create(form)
    new(nil, form).create
  end

  def initialize(model, form)
    @form = form
    @model = model || model_for_registration
  end

  def model_for_registration
    Cocina::Models::RequestAdminPolicy.new(
      label: title,
      version: 1,
      type: Cocina::Models::ObjectType.admin_policy,
      administrative: {
        hasAdminPolicy: SolrDocument::UBER_APO_ID,
        hasAgreement: agreement_object_id,
        accessTemplate: { view: 'world', download: 'world' }
      }
    )
  end

  def new_record?
    model.is_a? Cocina::Models::RequestAdminPolicy
  end

  def update
    updated = sync

    # TODO: If update went through sdr-api, we wouldn't have to start accessioning separately.
    response = Repository.store(updated)
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

  attr_reader :model, :form

  delegate :use_license, :agreement_object_id, :use_statement, :copyright_statement,
           :title, :default_workflows, :permissions,
           :view_access, :download_access, :access_location, :controlled_digital_lending,
           :collection_radio, :collections_for_registration, :collection,
           :registered_by, :changed?, to: :form

  def tag_registered_by(druid)
    return unless registered_by

    tags_client(druid).create(tags: ["Registered By : #{registered_by}"])
  end

  def tags_client(druid)
    Dor::Services::Client.object(druid).administrative_tags
  end

  def updated_description(updated)
    description = { title: [{ value: title }], purl: model.description.purl }
    updated_description = updated.description.new(description)
    updated.new(description: updated_description)
  end

  def updated_administrative(updated)
    updated_template = updated.administrative.accessTemplate.new(access_template)

    administrative = {
      hasAgreement: agreement_object_id,
      registrationWorkflow: registration_workflow,
      collectionsForRegistration: collection_ids,
      accessTemplate: updated_template,
      roles:
    }.compact

    updated_administrative = updated.administrative.new(administrative)
    updated.new(administrative: updated_administrative)
  end

  # The map between the change set fields and the Cocina field names
  ACCESS_FIELDS = {
    copyright_statement: :copyright, # TODO: Change to copyright to match ItemChangeSet
    use_license: :license, # TODO: Change to license to match ItemChangeSet
    use_statement: :useAndReproductionStatement,
    view_access: :view,
    download_access: :download,
    access_location: :location,
    controlled_digital_lending: :controlledDigitalLending
  }.freeze

  # TODO: dedupliate with ItemChangeSetPersister
  def access_template
    {}.tap do |access_properties|
      ACCESS_FIELDS.filter { |field, _cocina_field| changed?(field) }.each do |field, cocina_field|
        val = public_send(field)
        access_properties[cocina_field] = val.is_a?(String) ? val.presence : val # allow boolean false
      end
    end
  end

  # Rails adds a hidden item with blank on the form so that we know they wanted to
  # update the workflows, but selected none. We filter that out for persistence.
  def registration_workflow
    default_workflows.compact_blank
  end

  # Retrieves the list of existing collections from the form and makes a new collection
  # if they've selected that.
  # @returns [Array<String>] a list of collection druids for this AdminPolicy
  def collection_ids
    # Get the ids of the existing collections from the form.
    collection_ids = Hash(collections_for_registration).values.map { |elem| elem.fetch(:id) }
    if collection_radio == 'create'
      collection_ids << create_collection(model.externalIdentifier)
    elsif collection[:collection].present? # guard against empty string
      collection_ids << collection[:collection]
    end
    collection_ids
  end

  # Create a collection
  # @param [String] apo_druid the identifier for this APO
  # @return [String] the druid for the newly created collection
  def create_collection(apo_druid)
    form = CollectionForm.new
    form.validate(collection.merge(apo_druid:))
    form.save
    form.model.externalIdentifier
  end

  # Translate the value used on the form to the value used in Cocina
  ROLE_NAME = {
    'manage' => 'dor-apo-manager',
    'view' => 'dor-apo-viewer'
  }.freeze

  def roles
    return [] if permissions.blank?

    attributes = permissions.values
    ungrouped_perms = attributes.each_with_object({}) do |perm, grouped|
      role_name = ROLE_NAME.fetch(perm[:access])
      grouped[role_name] ||= []
      grouped[role_name] << { type: 'workgroup', identifier: "sdr:#{perm[:name]}" }
    end

    ungrouped_perms.map { |name, members| { name:, members: } }
  end
end
