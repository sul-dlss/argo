class BulkAction < ActiveRecord::Base
  belongs_to :bulk_actionable, polymorphic: true
  has_one :bulk_action_status
  belongs_to :user
end
