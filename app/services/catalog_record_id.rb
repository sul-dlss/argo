# frozen_string_literal: true

class CatalogRecordId
  # NOTE: This block is a container of simple class methods meant to impose an
  #       abstraction layer atop our specific library catalog implementation.
  class << self
    def other_links(model)
      new(model).other_links.map(&:catalogRecordId)
    end

    def valid?(catalog_record_ids)
      catalog_record_ids.all? { |id| id.match?(Regexp.new(pattern_string)) }
    end

    def label
      'Folio Instance HRID'
    end

    def manage_label
      "Manage #{label}"
    end

    def index_field
      SolrDocument::FIELD_FOLIO_INSTANCE_HRID
    end

    def pattern_string
      '\\A(L|a|in)[0-9]+\\z'
    end

    def html_pattern_string
      '^(L|a|in)[0-9]+$'
    end

    def indexing_prefix
      'folio'
    end

    def type
      'folio'
    end

    def previous_type
      "previous #{type}"
    end

    def other_type
      'symphony'
    end

    def csv_header
      @csv_header ||= label.downcase.tr(' ', '_')
    end
  end

  def self.links(model)
    new(model).links.map(&:catalogRecordId)
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
    removed_links = links.map(&:catalogRecordId) - new_catalog_record_ids
    links = (previous_links.map(&:catalogRecordId) + removed_links).map do |record_id|
      { catalog: self.class.previous_type, catalogRecordId: record_id, refresh: false }
    end.uniq
    links +
      other_links.map(&:to_h) +
      new_catalog_record_ids.map.with_index do |record_id, index|
        { catalog: self.class.type, catalogRecordId: record_id, refresh: refresh && index.zero? }
      end
  end

  def links
    find(self.class.type)
  end

  def other_links
    # Remove symphony links. See https://github.com/sul-dlss/argo/issues/4289
    find_not(self.class.type) - find(self.class.other_type)
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
    Array(@model.identification.catalogLinks).filter { |link| link.catalog == type }
  end

  def find_first(type)
    Array(@model.identification.catalogLinks).detect { |link| link.catalog == type }
  end

  def split(catalog_record_id)
    return [] unless catalog_record_id

    catalog_record_id.split(/\s*,\s*/)
  end
end
