# frozen_string_literal: true

# Stores data about an asynchonous background job
class BulkAction < ApplicationRecord
  belongs_to :user
  validates :action_type,
            inclusion: {
              in: %w(GenericJob
                     DescmetadataDownloadJob
                     ReleaseObjectJob
                     RemoteIndexingJob
                     SetGoverningApoJob
                     ManageCatkeyJob
                     PrepareJob
                     CloseVersionJob
                     ChecksumReportJob
                     DownloadReportJob
                     CreateVirtualObjectsJob)
            }

  before_destroy :remove_output_directory

  # A virtual attribute used for job creation but not persisted
  attr_accessor :pids, :manage_release, :set_governing_apo, :manage_catkeys, :prepare, :create_virtual_objects, :download_report
  attr_accessor :groups # the groups the user was a member of when they launched the job

  def file(filename)
    File.join(output_directory, filename)
  end

  def reset_druid_counts
    update_attribute(:druid_count_success, 0)
    update_attribute(:druid_count_fail, 0)
    update_attribute(:druid_count_total, 0)
  end

  def output_directory
    File.join(Settings.bulk_metadata.directory, prefix)
  end

  private

  def prefix
    "#{action_type}_#{id}"
  end

  def remove_output_directory
    FileUtils.rm_rf(output_directory)
  end
end
