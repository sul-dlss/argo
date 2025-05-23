# frozen_string_literal: true

class SerialsForm < ApplicationChangeSet
  property :part_label, virtual: true
  property :sort_key, virtual: true

  validates :part_label, presence: true, if: -> { sort_key.present? }

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    self.part_label = model.identification&.catalogLinks&.find { |link| link.catalog == 'folio' }&.partLabel
    self.sort_key = model.identification&.catalogLinks&.find { |link| link.catalog == 'folio' }&.sortKey
  end

  def save_model
    updated_model = model.new(identification: updated_identification)
    Repository.store(updated_model)
  end

  def updated_identification
    model.identification.new(catalogLinks: updated_catalog_links)
  end

  def updated_catalog_links
    model.identification.catalogLinks.map do |catalog_link|
      catalog_link_hash = catalog_link.to_h

      next catalog_link_hash.merge(partLabel: part_label&.strip, sortKey: sort_key&.strip) if catalog_link.catalog == 'folio'

      catalog_link_hash
    end
  end
end
