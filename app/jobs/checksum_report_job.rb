# frozen_string_literal: true

##
# Job to run checksum report
class ChecksumReportJob < GenericJob
  queue_as :default

  ##
  # A job that, given list of pids of objects, runs a checksum report using a presevation_catalog API endpoint and returns a CSV file to the user
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array]  :pids required list of pids
  # @option params [Array]  :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array]  :user the user
  # @option params [String] :output_directory the output directory to write the CSV checksum report to
  def perform(bulk_action_id, params)
    super
    report_filename = generate_report_filename(params[:output_directory])

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count
      begin
        raise "#{Time.current} ChecksumReportJob not authorized to view all content}" unless ability.can?(:view_content, ActiveFedora::Base)

        csv_report = Preservation::Client.objects.checksums(druids: pids)
        File.open(report_filename, 'w') { |file| file.write(csv_report) }
        bulk_action.update(druid_count_success: pids.length) # this whole job is run in one call, so it either all succeeds or fails
      rescue StandardError => e
        bulk_action.update(druid_count_fail: pids.length)
        message = exception_message_for(e)
        log.puts(message) # this one goes to the user via the bulk action log
        logger.error(message) # this is for later archaeological digs
        Honeybadger.context(bulk_action_id: bulk_action_id, params: params)
        Honeybadger.notify(message) # this is so the devs see it ASAP
      end
      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
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
end
