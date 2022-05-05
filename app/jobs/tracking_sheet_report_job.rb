# frozen_string_literal: true

##
# Job to create downloadable tracking sheets
class TrackingSheetReportJob < GenericJob
  ##
  # A job that...
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  def perform(bulk_action_id, params)
    super

    druids = params[:druids]

    with_bulk_action_log do |log|
      update_druid_count
      begin
        pdf = TrackSheet.new(druids).generate_tracking_pdf
        pdf.render_file(generate_report_filename(bulk_action.output_directory))
        bulk_action.update(druid_count_success: druids.length)
      rescue StandardError => e
        bulk_action.update(druid_count_fail: druids.length)
        error_message = "#{Time.current} TrackingSheetReportJob creation failed #{e.class} #{e.message}"
        log.puts(error_message) # this one goes to the user via the bulk action log
        logger.error(error_message) # this is for later archaeological digs
        Honeybadger.context(bulk_action_id:, params:)
        Honeybadger.notify(error_message) # this is so the devs see it ASAP
      end
    end
  end

  protected

  def generate_report_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.tracking_sheet_report_job.pdf_filename)
  end
end
