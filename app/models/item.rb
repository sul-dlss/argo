# frozen_string_literal: true

class Item < ApplicationModel
  define_attribute_methods :id, :version, :type, :admin_policy_id, :catkeys,
                           :collection_ids, :copyright, :embargo, :license,
                           :source_id, :use_statement, :barcode,
                           :view_access, :download_access, :access_location, :controlled_digital_lending,
                           :file_sets, :members, :release_tags

  attribute :id
  attribute :version
  attribute :type
  attribute :admin_policy_id
  attribute :catkeys
  attribute :collection_ids
  attribute :copyright
  attribute :embargo
  attribute :license
  attribute :source_id
  attribute :use_statement
  attribute :barcode
  attribute :view_access
  attribute :download_access
  attribute :access_location
  attribute :controlled_digital_lending
  attribute :file_sets
  attribute :members
  attribute :release_tags

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.id = model.externalIdentifier
    self.version = model.version
    self.type = model.type
    self.admin_policy_id = model.administrative.hasAdminPolicy

    self.catkeys = Catkey.symphony_links(model)
    self.barcode = model.identification.barcode
    self.source_id = model.identification.sourceId

    setup_acccess_properties!

    self.collection_ids = Array(model.structural&.isMemberOf)
    self.file_sets = model.structural.contains.map { |cocina| FileSet.new(cocina) }
    self.members = Array(model.structural.hasMemberOrders&.first&.members)
    self.release_tags = model.administrative.releaseTags
  end

  def setup_acccess_properties!
    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license

    self.view_access = model.access.view
    self.download_access = model.access.download
    self.access_location = model.access.location
    self.controlled_digital_lending = model.access.controlledDigitalLending
    self.embargo = Embargo.new(model.access.embargo) if model.access.embargo
  end

  def save
    @model = ItemPersister.update(model, self)
  end

  # This checks to see if the embargo or any of the properties of the embargo changed
  def embargo_changed?
    super || embargo&.changed?
  end

  # has the collection or any of its members changed?
  def file_sets_changed?
    super || file_sets.any?(&:changed?)
  end

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Item')
  end
end
