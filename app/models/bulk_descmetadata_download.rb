class BulkDescmetadataDownload < ActiveRecord::Base
  has_one :bulk_action, as: :bulk_actionable
end
