# frozen_string_literal: true

##
# Job to create downloadable tracking sheets
class TrackingSheetReportJob < BulkActionJob
  def perform_bulk_action
    pdf = TrackSheet.new(druids).generate_tracking_pdf
    pdf.render_file(report_filename)
    bulk_action.update!(druid_count_success: druid_count)
  rescue StandardError => e
    log("TrackingSheetReportJob creation failed #{e.class} #{e.message}")
    bulk_action.update!(druid_count_fail: druid_count)
    Honeybadger.notify(e)
  end

  private

  def report_filename
    File.join(bulk_action.output_directory, Settings.tracking_sheet_report_job.pdf_filename)
  end
end
