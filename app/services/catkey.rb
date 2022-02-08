# frozen_string_literal: true

class Catkey
  SYMPHONY = 'symphony'
  PREVIOUS_CATKEY = 'previous symphony'

  def self.deserialize(model)
    new(model).deserialize
  end

  def self.serialize(model, catkey)
    new(model).serialize(catkey)
  end

  def initialize(model)
    @model = model
  end

  def deserialize
    symphony_links.join(', ')
  end

  # If there was already a catkey in the record, store that in the "previous" spot (assuming there is no change)
  # @param [String] catkey a single catkey or a comma-separated list of catkeys
  # @return [Array<Hash>] a list of catalog links
  def serialize(catkey)
    new_catkeys = split(catkey)
    removed_links = symphony_links - new_catkeys
    links = (previous_links + removed_links).map { |record_id| { catalog: PREVIOUS_CATKEY, catalogRecordId: record_id } }.uniq

    links + new_catkeys.map { |record_id| { catalog: 'symphony', catalogRecordId: record_id } }
  end

  def symphony_links
    find(SYMPHONY)
  end

  def previous_links
    find(PREVIOUS_CATKEY)
  end

  def find(type)
    Array(@model.identification&.catalogLinks).filter_map { |link| link.catalogRecordId if link.catalog == type }
  end

  def split(catkey)
    return [] unless catkey

    catkey.split(/\s*,\s*/)
  end
end
