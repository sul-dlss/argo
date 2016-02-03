class BulkAction < ActiveRecord::Base
  belongs_to :user
  after_create :process_bulk_action_type

  # A virtual attribute used for job creation but not persisted
  attr_accessor :pids

  def file(filename)
    File.join(output_directory, filename)
  end

  private

  def prefix
    "#{action_type}_#{id}"
  end
  
  def output_directory
    File.join(Settings.BULK_METADATA.DIRECTORY, prefix)
  end

  def create_log_file
    log_filename = file(Settings.BULK_METADATA.LOG)
    FileUtils.touch(log_filename)
    update_attribute(:log_name, log_filename)
  end

  def create_output_directory
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end

  
  def process_bulk_action_type
    druid_list = ['druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979']
    create_output_directory
    create_log_file
    action_type.constantize.perform_later(druid_list, id, output_directory)
    update_attribute(:status, 'Scheduled Action')
  end
end
