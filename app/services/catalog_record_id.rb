# frozen_string_literal: true

class CatalogRecordId
  # NOTE: This block is a junk drawer of simple class methods meant to help
  #       switch between Symphony and Folio catalog implementations, and can be
  #       dumped or in-lined once we're done with Symphony for good.
  class << self
    def other_links(model)
      new(model).other_links.map(&:catalogRecordId)
    end

    def valid?(catalog_record_ids)
      catalog_record_ids.all? { |id| id.match?(Regexp.new(pattern_string)) }
    end

    def label
      return "Folio Instance HRID" if Settings.enabled_features.folio

      "Catkey"
    end

    def manage_label
      return "Manage Folio Instance HRID" if Settings.enabled_features.folio

      "Manage catkey"
    end

    def index_field
      return SolrDocument::FIELD_FOLIO_INSTANCE_HRID if Settings.enabled_features.folio

      SolrDocument::FIELD_CATKEY_ID
    end

    def pattern_string
      return "\\A(L|a|in)[0-9]+\\z" if Settings.enabled_features.folio

      "\\A[0-9]+\\z"
    end

    def html_pattern_string
      return "^(L|a|in)[0-9]+$" if Settings.enabled_features.folio

      "^[0-9]+$"
    end

    def indexing_prefix
      return "folio" if Settings.enabled_features.folio

      "catkey"
    end

    def type
      return "folio" if Settings.enabled_features.folio

      "symphony"
    end

    def previous_type
      return "previous folio" if Settings.enabled_features.folio

      "previous symphony"
    end
  end

  def self.links(model)
    new(model).links
  end

  def self.serialize(model, catalog_record_ids, refresh: true)
    new(model).serialize(catalog_record_ids, refresh:)
  end

  def self.link_refresh(model)
    new(model).link_refresh
  end

  def initialize(model)
    @model = model
  end

  # If there was already a catalog record ID in the record, store that in the "previous" spot (assuming there is no change)
  # @param [Array<String>] new_catalog_record_ids a list of catalog record IDs
  # @param [boolean] refresh first catalog record ID
  # @return [Array<Hash>] a list of catalog links
  def serialize(new_catalog_record_ids, refresh: true)
    removed_links = links - new_catalog_record_ids
    links = (previous_links + removed_links).map { |record_id| {catalog: self.class.previous_type, catalogRecordId: record_id, refresh: false} }.uniq
    links +
      other_links.map(&:to_h) +
      new_catalog_record_ids.map.with_index { |record_id, index| {catalog: self.class.type, catalogRecordId: record_id, refresh: refresh && index.zero?} }
  end

  def links
    find(self.class.type)
  end

  def other_links
    find_not(self.class.type)
  end

  def link_refresh
    find_first(self.class.type)&.refresh || false
  end

  def previous_links
    find(self.class.previous_type)
  end

  def find_not(type)
    Array(@model.identification.catalogLinks).reject { |link| link.catalog.include?(type) }
  end

  def find(type)
    Array(@model.identification.catalogLinks).filter_map { |link| link.catalogRecordId if link.catalog == type }
  end

  def find_first(type)
    Array(@model.identification.catalogLinks).detect { |link| link.catalog == type }
  end

  def split(catalog_record_id)
    return [] unless catalog_record_id

    catalog_record_id.split(/\s*,\s*/)
  end
end
