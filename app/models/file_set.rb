# frozen_string_literal: true

class FileSet < ApplicationModel
  define_attribute_methods :files, :type, :label

  attribute :files
  attribute :type
  attribute :label

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.type = model.type
    self.label = model.label
    self.files = model.structural.contains.map { |cocina| ManagedFile.new(cocina) }
  end

  # has the collection or any of its members changed?
  def changed?
    super || files.any?(&:changed?)
  end
end
