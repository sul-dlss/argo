# frozen_string_literal: true

# Validate the descriptive metadata spreadsheet
class DescriptionValidator
  def initialize(csv, bulk_job: false)
    @csv = csv
    @headers = csv.headers
    @bulk_job = bulk_job # indicates if validating from a bulk job
    @errors = []
  end

  attr_reader :errors

  def valid?
    validate_headers
    validate_rows
    errors.empty?
  end

  def validate_headers
    duplicate_headers.each do |header|
      errors << "Duplicate column headers: The header #{header} should occur only once."
    end
    errors << 'Druid column not found.' if @bulk_job && @headers.exclude?('druid')
    invalid_headers.each do |invalid_header|
      errors << "Column header invalid: #{invalid_header}."
    end
  end

  def validate_rows
    duplicate_druids.each do |druid|
      errors << "Duplicate druids: The druid \"#{druid}\" should occur only once."
    end
    @csv.each.with_index(2) do |row, i|
      errors << "Missing druid: No druid present in row #{i}." if row['druid'].blank?
    end
  end

  private

  def duplicate_headers
    @headers.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end

  def invalid_headers
    # The source_id and druid are only there for the user to reference, and we already validate the druid column is present
    @headers.excluding('source_id', 'druid').map do |address|
      split_address = address.scan(/[[:alpha:]]+|[[:digit:]]+/)
                             .map { |item| /\d+/.match?(item) ? item.to_i - 1 : item.to_sym }
      address unless Cocina::Models::Description.has_attribute? split_address[0].to_sym
    end.compact
  end

  def duplicate_druids
    @csv.map { |row| row['druid'] }.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end
end
