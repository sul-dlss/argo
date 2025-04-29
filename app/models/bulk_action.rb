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
                     DescriptiveMetadataExportJob
                     DescriptiveMetadataImportJob
                     ReleaseObjectJob
                     RemoteIndexingJob
                     PurgeJob
                     SetGoverningApoJob
                     SetCatalogRecordIdsAndBarcodesCsvJob
                     OpenVersionJob
                     RefreshModsJob
                     RepublishJob
                     CloseVersionJob
                     ChecksumReportJob
                     CreateVirtualObjectsJob
                     ExportTagsJob
                     ImportTagsJob
                     ExportStructuralJob
                     ImportStructuralJob
                     RegisterDruidsJob
                     SetLicenseAndRightsStatementsJob
                     SetSourceIdsCsvJob
                     SetContentTypeJob
                     ManageEmbargoesJob
                     SetCollectionJob
                     SetRightsJob
                     ValidateCocinaDescriptiveJob
                     TrackingSheetReportJob
                     ExportCocinaJsonJob
                     TextExtractionJob
                     ExportCatalogLinksJob]
            }

  after_create :create_output_directory, :create_log_file
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
    File.exist?(path) && !File.empty?(path)
  end

  def reset_druid_counts
    update_attribute(:druid_count_success, 0)
    update_attribute(:druid_count_fail, 0)
    update_attribute(:druid_count_total, 0)
  end

  def output_directory
    File.join(Settings.bulk_metadata.directory, prefix)
  end

  def create_log_file
    log_filename = file(Settings.bulk_metadata.log)
    FileUtils.touch(log_filename)
    update(log_name: log_filename)
  end

  def create_output_directory
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end

  def enqueue_job(job_params)
    active_job_class.perform_later(id, job_params)
    update(status: 'Scheduled Action')
  end

  private

  def active_job_class
    action_type.constantize
  end

  def prefix
    "#{action_type}_#{id}"
  end

  def remove_output_directory
    FileUtils.rm_rf(output_directory)
  end
end
