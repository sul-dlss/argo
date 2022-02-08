# frozen_string_literal: true

module Catkey
  def self.deserialize(model)
    Array(model.identification.catalogLinks).filter_map { |link| link.catalogRecordId if link.catalog == 'symphony' }.join(', ')
  end

  def self.serialize(catkey)
    catkey.present? ? catkey.split(/\s*,\s*/).map { |record_id| { catalog: 'symphony', catalogRecordId: record_id } } : nil
  end
end
