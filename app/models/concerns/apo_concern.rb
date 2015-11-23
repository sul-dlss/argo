module ApoConcern
  extend Blacklight::Solr::Document

  FIELD_APO_ID = :is_governed_by_ssim
  FIELD_APO_TITLE = :apo_title_ssim

  UBER_APO_ID = 'druid:hv992ry2431' # TODO: Uber-APO is hardcoded

  ##
  # Access a SolrDocument's APO druid
  # @return [String, nil]
  def apo_id
    fetch(FIELD_APO_ID).first
  rescue KeyError
    id == UBER_APO_ID ? id : nil
  end

  ##
  # Access a SolrDocument's APO druid without the `info:fedora/` prefix
  # @return [String, nil]
  def apo_pid
    apo_id.gsub('info:fedora/', '')
  rescue NoMethodError
    nil
  end

  ##
  # Access a SolrDocument's APO title
  # @return [String, nil]
  def apo_title
    fetch(FIELD_APO_TITLE).first
  rescue KeyError
    id == UBER_APO_ID ? title : nil
  end
end
