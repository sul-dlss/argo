# frozen_string_literal: true

# Represents a set of changes to a collection
class CollectionChangeSet
  PROPERTIES = %i[
    copyright_statement
    license
    use_statement
  ].freeze

  def initialize(attributes = {})
    @changes = attributes.slice(*PROPERTIES)
    yield self if block_given?
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
