module EmbargoConcern
  extend Blacklight::Solr::Document

  FIELD_EMBARGO_RELEASE_DATE  = :embargo_release_dtsim
  FIELD_EMBARGO_STATUS        = :embargo_status_ssim

  def embargo_release_date
    fetch(FIELD_EMBARGO_RELEASE_DATE)
  end

  def embargo_status
    fetch(FIELD_EMBARGO_STATUS)
  rescue KeyError
    nil
  end
end
