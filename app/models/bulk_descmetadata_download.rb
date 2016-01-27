class BulkDescmetadataDownload < ActiveRecord::Base
  has_one :bulk_action, as: :bulk_actionable

  # Base model for downloading descriptive metadata in bulk. Should start a delayed job given a user selection of
  # druids to work on. Will need another class in app/jobs/ that implements perform_later().
end
