class BulkAction < ActiveRecord::Base
  belongs_to :bulk_actionable, polymorphic: true
  has_one :bulk_action_status
  belongs_to :user

  # BulkAction is intended as a class to associate users and their various bulk actions. Examples of such
  # actions include uploading descmetadata via spreadsheets and downloading the descmetadata from a druid list.
  # Each BulkAction has a BulkActionStatus, which holds job information and error messages. A BulkAction
  # instance is only 'metadata' for jobs - it's not intended to actually run jobs itself. BulkAction could
  # provide the entry point for users to start new bulk jobs and view their old bulk jobs.

  def initialize(owner)
    
  end
end
