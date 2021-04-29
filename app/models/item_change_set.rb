# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catkey, virtual: true
  property :collection_ids, virtual: true
  property :copyright_statement, virtual: true
  property :embargo_release_date, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true

  def self.model_name
    Struct.new(:param_key, :route_key, :i18n_key, :name).new('item', 'item', 'item', 'Item')
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    return unless model.identification

    self.catkey = model.identification.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
    self.barcode = model.identification.barcode
  end

  def save_model
    ItemChangeSetPersister.update(model, self)
  end
end
