module CatkeyConcern
  extend Blacklight::Solr::Document

  FIELD_CATKEY_ID = :catkey_id_ssim

  ##
  # Access a SolrDocument's catkey
  # @return [String, nil]
  def catkey
    fetch(FIELD_CATKEY_ID).first
  rescue KeyError, NoMethodError
    nil
  end

  ##
  # Access a SolrDocument's catkey identifier
  # @return [String, nil]
  def catkey_id
    catkey.gsub(/^catkey:/, '')
  rescue NoMethodError
    nil
  end
end
