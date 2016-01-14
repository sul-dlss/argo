class BulkAction < ActiveRecord::Base
  belongs_to :user

  attr_accessor :status

  # Creates a new BulkAction.
  # @param[Integer] druid_count     Number of druids to work on, by default zero.
  def initialize(druid_count=0)
    @druid_count_success = 0
    @druid_count_fail = 0
    @druid_count_total = druid_count
  end

  def increment_success
    @druid_count_success += 1
  end

  def increment_fail
    @druid_count_fail += 1
  end
end
