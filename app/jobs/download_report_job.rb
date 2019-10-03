# frozen_string_literal: true

##
# Job to download a report from previous search results
class DownloadReportJob < GenericJob
  queue_as :default

  attr_accessor :report

  ##
  # A job that, given search params and columns, runs a download report and saves a CSV file for the user
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array]  :the search params and fields requested for the report
  # @option params [Array]  :user the user
  # @option params [String] :output_directory the output directory to write the CSV download report to
  def perform(bulk_action_id, params)
    super
    report_filename = generate_report_filename(params[:output_directory])

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      begin
        search_params = JSON.parse(params[:download_report][:search_params]).with_indifferent_access # reconstruct hash from the json string representation
        fields = params[:download_report][:selected_columns]
        log.puts("#{Time.current} Running report with #{search_params} for fields #{fields}")
        @current_user.set_groups_to_impersonate(@groups)
        @report = Report.new(search_params, fields, current_user: @current_user)
        bulk_action.update(druid_count_total: @report.num_found)
        File.open(report_filename, 'w') { |file| file.write(@report.to_csv) }
        bulk_action.update(druid_count_success: @report.num_found) # this whole job is run in one call, so it either all succeeds or fails
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

  ##
  # Generate a filename for the job's csv report output file.
  # @param  [String] output_dir Where to store the csv file.
  # @return [String] A filename for the csv file.
  def generate_report_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.download_report_job.csv_filename)
  end
end
