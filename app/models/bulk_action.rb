# frozen_string_literal: true

class BulkAction < ApplicationRecord
  belongs_to :user
  validates :action_type, inclusion: { in: %w(GenericJob DescmetadataDownloadJob ReleaseObjectJob RemoteIndexingJob SetGoverningApoJob ManageCatkeyJob) }
  after_create do
    create_output_directory
    create_log_file
    process_bulk_action_type
  end
  before_destroy :remove_output_directory

  # A virtual attribute used for job creation but not persisted
  attr_accessor :pids, :manage_release, :set_governing_apo, :manage_catkeys
  attr_accessor :groups # the groups the user was a member of when they launched the job

  def file(filename)
    File.join(output_directory, filename)
  end

  def reset_druid_counts
    update_attribute(:druid_count_success, 0)
    update_attribute(:druid_count_fail, 0)
    update_attribute(:druid_count_total, 0)
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
      manage_release: manage_release,
      set_governing_apo: set_governing_apo,
      manage_catkeys: manage_catkeys,
      groups: groups
    }
  end

  def process_bulk_action_type
    action_type.constantize.perform_later(id, job_params)
    update_attribute(:status, 'Scheduled Action')
  end
end
