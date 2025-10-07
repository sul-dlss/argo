# frozen_string_literal: true

# Validates a CSV that is uploaded as part of Bulk Actions.
class CsvUploadValidator
  # @return [Array<String>] array of error messages
  attr_reader :errors

  # @param [String] csv to validate (which has already been run through CsvUploadNormalizer)
  # @param [String,Array<String>] headers required to be present in the CSV
  def initialize(csv:, required_headers:)
    @csv = CSV.parse(csv, headers: true)
    @required_headers = Array(required_headers)
    @errors = []
  end

  def valid?
    self.errors += ["missing headers: #{missing_headers.join(', ')}."] if missing_headers.present?
    self.errors += Array(yield csv) if block_given?

    errors.empty?
  end

  private

  attr_reader :csv, :required_headers
  attr_writer :errors

  def missing_headers
    @missing_headers ||= required_headers.select { |required_header| csv.headers.exclude?(required_header) }
  end
end
