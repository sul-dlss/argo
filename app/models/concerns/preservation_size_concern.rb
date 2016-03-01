module PreservationSizeConcern
  include ActionView::Helpers::NumberHelper
  extend Blacklight::Solr::Document

  FIELD_PRESERVATION_SIZE = :preserved_size_dbtsi

  def preservation_size
    fetch(FIELD_PRESERVATION_SIZE, nil)
  end
end
