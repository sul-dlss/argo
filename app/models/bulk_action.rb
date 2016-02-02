class BulkAction < ActiveRecord::Base
  belongs_to :user
  after_create :process_bulk_action_type

  private

  def process_bulk_action_type
    druid_list = ['druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979']
    action_type.constantize.perform_later(druid_list, id, 'tmp/')
    update_attribute(:status, 'Scheduled Action')
  end
end
