# frozen_string_literal: true

# Validates a CSV that is uploaded as part of Bulk Actions.
class CsvUploadValidator
  # Validates that the required headers are present in the CSV.
  class RequiredHeaderValidator
    def initialize(headers:)
      @required_headers = headers
    end

    def validate(csv:)
      missing_headers = required_headers.select { |required_header| csv.headers.exclude?(required_header) }
      return ["missing headers: #{missing_headers.join(', ')}."] if missing_headers.present?

      []
    end

    private

    attr_reader :required_headers
  end

  # Validates that data is present for one of the required columns.
  class OrRequiredDataValidator
    def initialize(headers:)
      @required_headers = headers
    end

    def validate(csv:)
      if missing_headers?(csv.headers)
        ["missing header. One of these must be provided: #{required_headers.join(', ')}"]
      elsif rows_with_missing_data?(csv)
        ["missing data. For each row, one of these must be provided: #{required_headers.join(', ')}"]
      else
        []
      end
    end

    private

    attr_reader :required_headers

    def missing_headers?(headers)
      @missing_headers ||= required_headers.none? { |required_header| headers.include?(required_header) }
    end

    def rows_with_missing_data?(csv)
      csv.any? do |row|
        required_headers.none? { |required_header| row[required_header].present? }
      end
    end
  end

  # @param [String] csv to validate
  # @param [Array<HeaderValidators>] validators to run against the csv's headers
  def initialize(csv:, header_validators: [])
    @raw_csv = csv
    @header_validators = Array(header_validators)
  end

  def valid?
    errors.empty?
  end

  # @return [Array<String>] array of error messages
  def errors
    @errors ||= header_validators.map { |validator| validator.validate(csv:) }.flatten
  end

  private

  attr_reader :raw_csv, :header_validators

  def csv
    @csv ||= begin
      parsed = CSV.parse(raw_csv, headers: true)
      remove_blank_rows_at_end(parsed)
    end
  end

  def remove_blank_rows_at_end(csv_table)
    last = csv_table.size - 1
    while csv_table[last].fields.all?(&:blank?) && last != 0
      csv_table.delete(last) if csv_table[last].fields.all?(&:blank?)
      last -= 1
    end
    csv_table
  end
end
