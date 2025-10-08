# frozen_string_literal: true

##
# Job to run checksum report
class ChecksumReportJob < BulkActionJob
  ##
  # A job that, given list of druids of objects, runs a checksum report using a presevation_catalog API endpoint and returns a CSV file to the user
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array]  :druids required list of druids
  # @option params [Array]  :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array]  :user the user
  def perform_bulk_action
    return unless check_view_ability?

    super
  end

  def export_file
    @export_file ||= CSV.open(report_filename, 'w')
  end

  class ChecksumReportJobItem < BulkActionJobItem
    def perform
      report = Preservation::Client.objects.checksum(druid:)
      report.each do |row|
        export_file << [druid, row['filename'], row['md5'], row['sha1'], row['sha256'], row['filesize']]
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
