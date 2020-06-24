# frozen_string_literal: true

# Stores data about an asynchonous background job
class BulkAction < ApplicationRecord
  belongs_to :user
  validates :action_type,
            inclusion: {
              in: %w[GenericJob
                     DescmetadataDownloadJob
                     ReleaseObjectJob
                     RemoteIndexingJob
                     PurgeJob
                     SetGoverningApoJob
                     ManageCatkeyJob
                     PrepareJob
                     RepublishJob
                     SetTagsJob
                     CloseVersionJob
                     ChecksumReportJob
                     CreateVirtualObjectsJob]
            }

  before_destroy :remove_output_directory

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
