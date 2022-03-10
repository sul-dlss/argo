# frozen_string_literal: true

# Stores data about an asynchonous background job
class BulkAction < ApplicationRecord
  belongs_to :user
  validates :action_type,
            inclusion: {
              in: %w[GenericJob
                     AddWorkflowJob
                     ApplyApoDefaultsJob
                     DescmetadataDownloadJob
                     ReleaseObjectJob
                     RemoteIndexingJob
                     PurgeJob
                     SetGoverningApoJob
                     SetCatkeysAndBarcodesJob
                     SetCatkeysAndBarcodesCsvJob
                     PrepareJob
                     RefreshModsJob
                     RepublishJob
                     CloseVersionJob
                     ChecksumReportJob
                     CreateVirtualObjectsJob
                     ExportTagsJob
                     ImportTagsJob
                     ExportStructuralJob
                     RegisterDruidsJob
                     SetLicenseAndRightsStatementsJob
                     SetSourceIdsCsvJob
                     SetContentTypeJob
                     ManageEmbargoesJob
                     SetCollectionJob]
            }

  before_destroy :remove_output_directory

  def file(filename)
    File.join(output_directory, filename)
  end

  def completed?
    status == 'Completed'
  end

  def has_report?(filename)
    return false unless completed?

    path = file(filename)
    File.exist?(path) && !File.zero?(path)
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
