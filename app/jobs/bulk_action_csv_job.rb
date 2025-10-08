# frozen_string_literal: true

require 'csv'

# A super class for bulk jobs that take a CSV file as input.
class BulkActionCsvJob < BulkActionJob
  DRUID_COLUMN = 'druid'

  def perform_bulk_action
    return unless check_druid_column?

    csv.each.with_index(2) do |row, index|
      druid = row[DRUID_COLUMN]
      perform_item_class.new(druid:, index:, job: self, row:).perform
    rescue StandardError => e
      failure!(druid: druid, message: "Failed #{e.class} #{e.message}", index:)
    end
  end

  # Subclasses might want to override if need to provide custom parsing.
  def csv
    @csv ||= CSV.parse(params[:csv_file], headers: true)
  end

  # Subclasses might want to override if there is not a druid for every row.
  # For example, if there are blank rows to skip.
  def druid_count
    csv.length
  end

  def success!(druid:, message:, index:)
    bulk_action.increment(:druid_count_success).save
    log(" - line #{index} - #{message} for #{druid}")
  end

  def failure!(druid:, message:, index:)
    bulk_action.increment(:druid_count_fail).save
    log(" - line #{index} - #{message} for #{druid}")
  end

  # Subclasses can override this and return true if the check is not needed.
  def check_druid_column?
    return true if csv.headers.include?(DRUID_COLUMN)

    log("Column \"#{DRUID_COLUMN}\" not found")
    bulk_action.update(druid_count_fail: csv.size)
    false
  end
end
