# frozen_string_literal: true

class Catkey
  SYMPHONY = 'symphony'
  PREVIOUS_CATKEY = 'previous symphony'

  def self.symphony_links(model)
    new(model).symphony_links
  end

  def self.serialize(model, catkeys)
    new(model).serialize(catkeys)
  end

  def initialize(model)
    @model = model
  end

  # If there was already a catkey in the record, store that in the "previous" spot (assuming there is no change)
  # @param [Array<String>] new_catkeys a list of catkeys
  # @return [Array<Hash>] a list of catalog links
  def serialize(new_catkeys)
    removed_links = symphony_links - new_catkeys
    links = (previous_links + removed_links).map { |record_id| { catalog: PREVIOUS_CATKEY, catalogRecordId: record_id, refresh: false } }.uniq

    links + new_catkeys.map.with_index { |record_id, index| { catalog: SYMPHONY, catalogRecordId: record_id, refresh: index.zero? } }
  end

  def symphony_links
    find(SYMPHONY)
  end

  def previous_links
    find(PREVIOUS_CATKEY)
  end

  def find(type)
    Array(@model.identification.catalogLinks).filter_map { |link| link.catalogRecordId if link.catalog == type }
  end

  def split(catkey)
    return [] unless catkey

    catkey.split(/\s*,\s*/)
  end
end
