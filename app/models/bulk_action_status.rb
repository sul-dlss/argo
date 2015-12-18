class BulkActionStatus < ActiveRecord::Base
  has_many :bulk_action_messages
  belongs_to :bulk_action
end
