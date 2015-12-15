module EmbargoConcern
  extend Blacklight::Solr::Document

  FIELD_EMBARGO_STATUS       = :embargo_status_ssim
  FIELD_EMBARGO_RELEASE_DATE = :embargo_release_dtsim

  def embargoed?
    embargo_status == 'embargoed'
  end

  def embargo_status
    fetch(FIELD_EMBARGO_STATUS).first
  rescue NoMethodError, KeyError
    nil
  end

  def embargo_release_date
    fetch(FIELD_EMBARGO_RELEASE_DATE).first
  rescue NoMethodError, KeyError
    nil
  end
end
