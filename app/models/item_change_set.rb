# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet
  PROPERTIES = %i[
    admin_policy_id
    catkey
    collection_ids
    copyright_statement
    license
    source_id
    use_statement
  ].freeze

  def initialize
    @changes = {}
    yield self
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

  # Allows collaborators to ask if the change set includes *any* changes
  def changed?
    @changes.any?
  end
end
