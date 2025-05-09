# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catalog_record_ids, virtual: true
  # NOTE: Only needed while retaining Symphony IDs, as a way to quietly keep
  #       the non-active catalog's values in Cocina w/o wiping them out.
  property :other_catalog_record_ids, virtual: true
  property :refresh, virtual: true
  property :collection_ids, virtual: true
  property :copyright, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true
  property :part_label, virtual: true
  property :sort_key, virtual: true

  include HasViewAccessWithCdl

  validates :source_id, presence: true, if: -> { changed?(:source_id) }
  validates :barcode, format: {
    with: /\A(2050[0-9]{7}|245[0-9]{8}|36105[0-9]{9}|[0-9]+-[0-9]+)\z/,
    allow_blank: true
  }
  validates :part_label, presence: true, if: -> { sort_key.present? }
  validate :format_of_catalog_record_ids

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Item')
  end

  def id
    model.externalIdentifier
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    if model.identification
      self.catalog_record_ids = CatalogRecordId.links(model)
      self.other_catalog_record_ids = CatalogRecordId.other_links(model)
      self.refresh = CatalogRecordId.link_refresh(model)
      self.barcode = model.identification.barcode
      self.source_id = model.identification.sourceId
      self.part_label = CatalogRecordId.part_label(model)
      self.sort_key = CatalogRecordId.sort_key(model)
    end

    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license
    setup_view_access_with_cdl_properties(model.access)
  end

  def format_of_catalog_record_ids
    return if catalog_record_ids.blank? || CatalogRecordId.valid?(catalog_record_ids)

    errors.add(:catalog_record_ids, 'are not a valid format')
  end

  def sync
    super
    self.download_access = 'none' if clear_download? # This must be before clearing location
    self.access_location = nil if clear_location?
  end

  def clear_download?
    %w[dark citation-only].include?(view_access)
  end

  def clear_location?
    (changed?(:view_access) || changed?(:download_access)) && view_access != 'location-based' && download_access != 'location-based'
  end

  # @raises [Dor::Services::Client::UnexpectedResponse] when an error occurs updating the object
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    updated = model
    # Can't update the files if the previous access was dark, as it triggers validation that may make the object invalid
    # updated = update_files(updated) if rights_changed? # This would ideally live in #sync, but reform doesn't support immutable models.
    ItemChangeSetPersister.update(updated, self)
  end

  def rights_changed?
    changed?(:view_access) || changed?(:download_access) || changed?(:location) || changed?(:controlled_digital_lending)
  end
end
