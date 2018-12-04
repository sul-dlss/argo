# frozen_string_literal: true

module CatkeyConcern
  extend Blacklight::Solr::Document

  FIELD_CATKEY_ID = :catkey_id_ssim

  ##
  # Access a SolrDocument's catkey
  # @return [String, nil]
  def catkey
    first(FIELD_CATKEY_ID)
  end

  ##
  # Access a SolrDocument's catkey identifier
  # @return [String, nil]
  def catkey_id
    catkey&.gsub(/^catkey:/, '')
  end
end
