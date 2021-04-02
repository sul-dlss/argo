# frozen_string_literal: true

# Represents a set of changes to a collection
class CollectionChangeSet < ApplicationChangeSet
  property :catkey, virtual: true
  property :copyright_statement, virtual: true
  property :license, virtual: true
  property :use_statement, virtual: true

  def self.model_name
    Struct.new(:param_key, :route_key, :i18n_key, :name).new('collection', 'collection', 'collection', 'Collection')
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    return unless model.identification

    self.catkey = model.identification.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
  end

  def save_model
    CollectionChangeSetPersister.update(model, self)
  end
end
