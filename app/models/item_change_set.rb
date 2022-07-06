# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catkeys, virtual: true
  property :collection_ids, virtual: true
  property :copyright, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true

  include HasViewAccessWithCdl

  validates :source_id, presence: true, if: -> { changed?(:source_id) }
  validates :barcode, format: {
    with: /\A(2050[0-9]{7}|245[0-9]{8}|36105[0-9]{9}|[0-9]+-[0-9]+)\z/,
    allow_blank: true
  }

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Item')
  end

  def id
    model.externalIdentifier
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    if model.identification
      self.catkeys = Catkey.symphony_links(model)
      self.barcode = model.identification.barcode
      self.source_id = model.identification.sourceId
    end

    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license
    setup_view_access_with_cdl_properties(model.access)
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

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
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
