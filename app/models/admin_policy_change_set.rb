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

  attr_reader :model

  def save
    @model = if new_record?
               AdminPolicyChangeSetPersister.create(self)
             else
               AdminPolicyChangeSetPersister.update(model, self)
             end
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

  def collections_for_registration=(val)
    @changes[:collections_for_registration] = val
  end

  def collections_for_registration
    @changes[:collections_for_registration] || {}
  end

  # These attributes get passed to the CollectionForm
  def collection=(val)
    @changes[:collection] = val
  end

  def collection
    @changes[:collection]
  end
end
