# frozen_string_literal: true

# Represents a set of changes to a collection
class CollectionChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catalog_record_ids, virtual: true
  property :copyright, virtual: true
  property :license, virtual: true
  property :use_statement, virtual: true
  property :source_id, virtual: true
  property :view_access, virtual: true

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, "Collection")
  end

  def id
    model.externalIdentifier
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    self.catalog_record_ids = CatalogRecordId.links(model) if model.identification
    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license
    self.source_id = model.identification&.sourceId
    self.view_access = model.access.view
  end

  def save_model
    CollectionChangeSetPersister.update(model, self)
  end
end
