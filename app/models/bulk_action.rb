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

  private

  def process_bulk_action_type
    druid_list = ['druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979']
    action_type.constantize.perform_later(druid_list, id, 'tmp/')
  end
end
