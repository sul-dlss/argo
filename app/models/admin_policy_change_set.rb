# frozen_string_literal: true

# Represents a set of changes to an admin policy.
class AdminPolicyChangeSet
  PROPERTIES = %i[
    use_license
    registered_by
    agreement_object_id
    use_statement
    copyright_statement
    default_rights
    title
    permissions
    default_workflows
  ].freeze

  def initialize(model: nil)
    @model = model
    @changes = {}
    yield self if block_given?
  end

  attr_reader :model, :collection_id

  def save
    @model = if new_record?
               AdminPolicyChangeSetPersister.create(self)
             else
               AdminPolicyChangeSetPersister.update(model, self)
             end
    @collection_id = create_collection(model.externalIdentifier) if collection_radio == 'create'
  end

  def new_record?
    model.nil?
  end

  def validate(params)
    params.each do |k, v|
      public_send("#{k}=", v.presence)
    end

    title.present? && agreement_object_id.present?
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

  PROPERTIES.each do |property|
    define_method(property) do
      @changes[property]
    end

    define_method("#{property}_changed?") do
      @changes.key?(property)
    end

    define_method("#{property}=") do |value|
      @changes[property] = value
    end
  end

  # Does the user want to create a new default collection
  def collection_radio=(val)
    @changes[:collection_radio] = val
  end

  def collection_radio
    @changes[:collection_radio]
  end

  # These attributes get passed to the CollectionForm
  def collection=(val)
    @changes[:collection] = val
  end

  def collection
    @changes[:collection]
  end
end
