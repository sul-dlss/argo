# frozen_string_literal: true

##
# Job to download a report from previous search results
class DownloadReportJob < GenericJob
  queue_as :default

  ##
  # A job that, given a search params, runs a download report for the selected columns and returns a CSV file to the user
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array]  :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array]  :user the user
  # @option params [String] :output_directory the output directory to write the CSV checksum report to
  def perform(bulk_action_id, params)
    super
    report_filename = generate_report_filename(params[:output_directory])

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      begin
        csv_report = download_report(params)
        File.open(report_filename, 'w') { |file| file.write(csv_report) }
      rescue StandardError => e
        bulk_action.update(druid_count_fail: 1)
        message = "#{Time.current} DownloadReportJob creation failed #{e.class} #{e.message}"
        log.puts(message)
        # if we couldn't write out the file, we have an issue
        Honeybadger.notify message
        raise message
      end
      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  # produce the report given the search results
  def download_report(params)
    log.puts("#{Time.current} Running report with #{params}")
    results = []
    bulk_action.update(druid_count_total: results.size)
    bulk_action.update(druid_count_success: results.size) # this whole job is run in one call, so it either all succeeds or fails
    results
  end

  ##
  # Generate a filename for the job's csv report output file.
  # @param  [String] output_dir Where to store the csv file.
  # @return [String] A filename for the csv file.
  def generate_report_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.download_report_job.csv_filename)
  end
end
