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
    @errors ||= header_errors
  end

  private

  attr_reader :csv, :headers

  def header_errors
    header_line = StringIO.new(csv).readline
    csv_table = CSV.parse(header_line, headers: true)
    missing_headers = headers.select { |header| csv_table.headers.exclude?(header) }
    return ["missing headers: #{missing_headers.join(', ')}."] if missing_headers.present?

    []
  end

  def catalog_record_id_column
    CatalogRecordId.label.downcase.tr(' ', '_')
  end
end
