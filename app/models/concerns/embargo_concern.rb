# frozen_string_literal: true

module EmbargoConcern
  extend Blacklight::Solr::Document

  FIELD_EMBARGO_STATUS       = :embargo_status_ssim
  FIELD_EMBARGO_RELEASE_DATE = :embargo_release_dtsim

  def embargoed?
    embargo_status == 'embargoed'
  end

  def embargo_status
    first(FIELD_EMBARGO_STATUS)
  end

  def embargo_release_date
    first(FIELD_EMBARGO_RELEASE_DATE)
  end
end
