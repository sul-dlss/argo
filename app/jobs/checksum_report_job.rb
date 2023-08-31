# frozen_string_literal: true

##
# Job to run checksum report
class ChecksumReportJob < GenericJob
  ##
  # A job that, given list of druids of objects, runs a checksum report using a presevation_catalog API endpoint and returns a CSV file to the user
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array]  :druids required list of druids
  # @option params [Array]  :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array]  :user the user
  def perform(bulk_action_id, params)
    super
    report_filename = generate_report_filename(bulk_action.output_directory)

    with_bulk_action_log do |log|
      update_druid_count
      begin
        raise "#{Time.current} ChecksumReportJob not authorized to view all content}" unless ability.can?(:view_content, Cocina::Models::DRO)

        CSV.open(report_filename, "w") do |csv|
          druids.each do |druid|
            report = Preservation::Client.objects.checksum(druid:)
            report.each do |row|
              csv << [druid, row["filename"], row["md5"], row["sha1"], row["sha256"], row["filesize"]]
            end
            bulk_action.increment(:druid_count_success).save
          rescue Preservation::Client::NotFoundError
            csv << [druid, "object not found or not fully accessioned"]
            bulk_action.increment(:druid_count_fail).save
            log.puts("#{Time.current} object not found or not fully accessioned for #{druid}")
          end
        end
      rescue => e
        bulk_action.update(druid_count_fail: druids.length, druid_count_success: 0)
        message = exception_message_for(e)
        log.puts(message) # this one goes to the user via the bulk action log
        logger.error(message) # this is for later archaeological digs
        Honeybadger.context(bulk_action_id:, params:)
        Honeybadger.notify(message) # this is so the devs see it ASAP
      end
    end
  end

  private

  def exception_message_for(exception)
    case exception
    when Preservation::Client::NotFoundError, Preservation::Client::UnexpectedResponseError
      "#{Time.current} ChecksumReportJob got error from Preservation Catalog API (#{exception.class}): #{exception.message}"
    when Preservation::Client::ConnectionFailedError
      "#{Time.current} ChecksumReportJob failed on call to Preservation Catalog API: (#{exception.class}): #{exception.message}"
    else # e.g., StandardError
      "#{Time.current} ChecksumReportJob creation failed #{exception.class} #{exception.message}"
    end
  end

  ##
  # Generate a filename for the job's csv report output file.
  # @param  [String] output_dir Where to store the csv file.
  # @return [String] A filename for the csv file.
  def generate_report_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.checksum_report_job.csv_filename)
  end

  def generate_report
  end
end
