class BulkAction < ActiveRecord::Base
  belongs_to :user
  validates :action_type, inclusion: { in: %w(GenericJob DescmetadataDownloadJob ReleaseObjectJob) }
  after_create do
    create_output_directory
    create_log_file
    process_bulk_action_type
  end
  before_destroy :remove_output_directory

  # A virtual attribute used for job creation but not persisted
  attr_accessor :pids, :manage_release

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

  def remove_output_directory
    FileUtils.rm_rf(output_directory)
  end

  ##
  # Returns a Hash of custom params that were sent through on initialization of
  # class, but aren't persisted and need to be passed to job.
  # @return [Hash]
  def job_params
    {
      pids: pids.split,
      output_directory: output_directory,
      manage_release: manage_release
    }
  end

  def process_bulk_action_type
    action_type.constantize.perform_later(id, job_params)
    update_attribute(:status, 'Scheduled Action')
  end
end
