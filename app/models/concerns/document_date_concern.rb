module DocumentDateConcern
  extend Blacklight::Solr::Document

  FIELD_REGISTERED_DATE       = :registered_dttsim
  FIELD_LAST_ACCESSIONED_DATE = :accessioned_latest_dttsi
  FIELD_LAST_PUBLISHED_DATE   = :published_latest_dttsi
  FIELD_LAST_SUBMITTED_DATE   = :submitted_latest_dttsi
  FIELD_LAST_DEPOSITED_DATE   = :deposited_latest_dttsi
  FIELD_LAST_MODIFIED_DATE    = :modified_latest_dttsi
  FIELD_LAST_OPENED_DATE      = :opened_latest_dttsi

  def registered_date
    fetch(FIELD_REGISTERED_DATE)
  end

  def accessioned_date
    fetch(FIELD_LAST_ACCESSIONED_DATE)
  end

  def published_date
    fetch(FIELD_LAST_PUBLISHED_DATE)
  end

  def submitted_date
    fetch(FIELD_LAST_SUBMITTED_DATE)
  end

  def deposited_date
    fetch(FIELD_LAST_DEPOSITED_DATE)
  end

  def modified_date
    fetch(FIELD_LAST_MODIFIED_DATE)
  end

  def opened_date
    fetch(FIELD_LAST_OPENED_DATE)
  end
end
