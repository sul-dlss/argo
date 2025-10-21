# frozen_string_literal: true

# A job that, given list of druids of objects, runs a checksum report using a presevation_catalog API endpoint and returns a CSV file to the user
class ChecksumReportJob < BulkActionJob
  HEADERS = %w[druid filename md5 sha1 sha256 size].freeze

  def perform_bulk_action
    return unless check_view_ability?

    super
  end

  def export_file
    @export_file ||= CSV.open(report_filename, 'w', write_headers: true, headers: HEADERS)
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
