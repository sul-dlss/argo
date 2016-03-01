module TitleConcern
  extend Blacklight::Solr::Document

  FIELD_TITLE = :dc_title_ssi

  ##
  # Access a SolrDocument's title
  # @return [String, nil]
  def title
    fetch(FIELD_TITLE, nil)
  end
end
