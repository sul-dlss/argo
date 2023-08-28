# frozen_string_literal: true

# Validates a CSV that is uploaded as part of Bulk Actions.
class CsvUploadValidator
  # @param [String] csv to validate
  # @param [Array<String>] headers that are required
  def initialize(csv:, headers:)
    @csv = csv
    @headers = headers
  end

  def valid?
    errors.empty?
  end

  # @return [Array<String>] array of error messages
  def errors
    @errors ||= [].tap do |errors|
      errors.concat(header_errors)
      errors.concat(data_errors)
    end
  end

  private

  attr_reader :csv, :headers

  def header_errors
    header_line = StringIO.new(csv).readline
    csv_table = CSV.parse(header_line, headers: true)
    missing_headers = headers.select { |header| csv_table.headers.exclude?(header) }
    return ["missing headers: #{missing_headers.join(", ")}."] if missing_headers.present?

    []
  end

  # NOTE: this method can be removed when we remove the ils_cutover_in_progress flag
  def data_errors
    return [] unless Settings.ils_cutover_in_progress

    CSV.parse(csv, headers: true).each do |row|
      # Short-circuit the iteration as soon as a problematic row is encountered
      return ["rows may not contain catalog record IDs during the ILS cutover"] if row[catalog_record_id_column].present?
    end

    []
  end

  def catalog_record_id_column
    CatalogRecordId.label.downcase.tr(" ", "_")
  end
end
