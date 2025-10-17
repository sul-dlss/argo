# frozen_string_literal: true

# A job that, given list of druids of objects, runs a checksum report using a presevation_catalog API endpoint and returns a CSV file to the user
class ChecksumReportJob < BulkActionJob
  def perform_bulk_action
    return unless check_view_ability?

    super
  end

  def export_file
    @export_file ||= CSV.open(report_filename, 'w').tap do |csv|
      # The CSV header needs to be injected before any item-level CSV is
      # generated. If this is moved into the job item's `#perform` method, the
      # header will be repeated once for every druid.
      csv << %w[druid filename md5 sha256 sha512 size]
    end
  end

  class ChecksumReportJobItem < BulkActionJobItem
    def perform
      Preservation::Client.objects.checksum(druid:).each do |hash|
        export_file << [druid, hash['filename'], hash['md5'], hash['sha1'], hash['sha256'], hash['filesize']]
      end

      success!
    rescue Preservation::Client::NotFoundError
      export_file << [druid, 'object not found or not fully accessioned']
      failure!(message: 'Object not found or not fully accessioned')
    end

    delegate :export_file, to: :job
  end

  private

  # Generate a filename for the job's csv report output file.
  # @return [String] A filename for the csv file.
  def report_filename
    File.join(bulk_action.output_directory, Settings.checksum_report_job.csv_filename)
  end
end
