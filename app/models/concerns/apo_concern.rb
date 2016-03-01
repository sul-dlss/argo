module ApoConcern
  extend Blacklight::Solr::Document

  FIELD_APO_ID = :is_governed_by_ssim
  FIELD_APO_TITLE = :apo_title_ssim

  UBER_APO_ID = 'druid:hv992ry2431' # TODO: Uber-APO is hardcoded
  HYDRUS_UBER_APO_ID = 'druid:zw306xn5593' # TODO: Hydrus Uber-APO is hardcoded
  UBER_APO_IDS = [UBER_APO_ID, HYDRUS_UBER_APO_ID]

  ##
  # Access a SolrDocument's APO druid
  # @return [String, nil]
  def apo_id
    if has? FIELD_APO_ID
      first(FIELD_APO_ID)
    elsif UBER_APO_IDS.include?(id)
      id
    end
  end

  ##
  # Access a SolrDocument's APO druid without the `info:fedora/` prefix
  # @return [String, nil]
  def apo_pid
    apo_id.gsub('info:fedora/', '') if apo_id
  end

  ##
  # Access a SolrDocument's APO title
  # @return [String, nil]
  def apo_title
    if has? FIELD_APO_TITLE
      first(FIELD_APO_TITLE)
    elsif UBER_APO_IDS.include?(id)
      title
    end
  end
end
