class BulkAction < ActiveRecord::Base
  belongs_to :user
  attr_accessor :status
  after_create :process_bulk_action_type

  def increment_success
    @druid_count_success += 1
  end

  def increment_fail
    @druid_count_fail += 1
  end
end
