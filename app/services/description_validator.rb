# frozen_string_literal: true

# Validate the descriptive metadata spreadsheet
class DescriptionValidator
  def initialize(csv)
    @csv = csv
    @headers = csv.headers
    @errors = []
  end

  attr_reader :errors

  def valid?
    duplicate_headers.each do |header|
      errors << "Duplicate column headers: The header #{header} should occur only once."
    end
    duplicate_druids.each do |druid|
      errors << "Duplicate druids: The druid \"#{druid}\" should occur only once."
    end
    required_headers.each do |required_header|
      errors << "#{required_header} column not found." unless @headers.include? required_header
    end
    @csv.each.with_index(2) do |row, i|
      errors << "Missing druid: No druid present in row #{i}." if row['druid'].blank?
    end
    errors.empty?
  end

  private

  def duplicate_headers
    @headers.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end

  def duplicate_druids
    @csv.map { |row| row['druid'] }.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end

  def required_headers
    %w[druid]
  end
end
