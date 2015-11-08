module CatkeyConcern
  extend Blacklight::Solr::Document

  ##
  # Access a SolrDocument's catkey
  # @return [String, nil]
  def catkey
    fetch(:catkey_id_ssim).first
  rescue KeyError
    nil
  end
end
