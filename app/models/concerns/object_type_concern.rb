# frozen_string_literal: true

module ObjectTypeConcern
  extend Blacklight::Solr::Document

  FIELD_OBJECT_TYPE = :objectType_ssim

  ##
  # Eventhough this is a multivalued Solr field, it should actually be treated
  # as a single valued field.
  def object_type
    first(FIELD_OBJECT_TYPE)
  end

  def admin_policy?
    object_type == 'adminPolicy'
  end
end
