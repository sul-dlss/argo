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
    validate_duplicate_headers
    validate_title_headers
    if @bulk_job
      validate_druid_headers
      validate_druid_rows
    end
    errors.empty?
  end

  def validate_duplicate_headers
    duplicate_headers.each do |header|
      errors << "Duplicate column headers: The header #{header} should occur only once."
    end
  end

  def validate_title_headers
    if @headers.include?('title1.value') ||
       (@headers.exclude?('title1.value') && @headers.include?('title1.structureValue1.type') && @headers.include?('title1.structureValue1.value'))
      return
    end

    errors << 'Title column not found.'
  end

  def validate_druid_headers
    errors << 'Druid column not found.' if @headers.exclude?('druid')
  end

  def validate_druid_rows
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

  def duplicate_druids
    @csv.map { |row| row['druid'] }.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end
end
