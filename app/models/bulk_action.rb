class BulkAction < ActiveRecord::Base
  belongs_to :user
  after_create :process_bulk_action_type

  private

  def prefix
    "#{action_type}_#{id}"
  end
  
  def output_directory
    new_output_dir = File.join(Settings.BULK_METADATA.DIRECTORY, prefix)
    FileUtils.mkdir_p(new_output_dir) unless File.directory?(new_output_dir)
    new_output_dir
  end

  
  def process_bulk_action_type
    druid_list = ['druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979']
    update_attribute(:log_name, File.join(output_directory, Settings.BULK_METADATA.LOG))
    action_type.constantize.perform_later(druid_list, id, output_directory)
    update_attribute(:status, 'Scheduled Action')
  end
end
