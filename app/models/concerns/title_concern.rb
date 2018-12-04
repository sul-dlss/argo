# frozen_string_literal: true

module TitleConcern
  extend Blacklight::Solr::Document

  FIELD_TITLE = :sw_display_title_tesim

  ##
  # Access a SolrDocument's title
  # @return [String, nil]
  def title
    fetch(FIELD_TITLE, nil)
  end
end
