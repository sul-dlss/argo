# frozen_string_literal: true

# Validate the descriptive metadata spreadsheet
class DescriptionValidator
  def initialize(csv)
    @headers = csv.headers
    @errors = []
  end

  attr_reader :errors

  def valid?
    duplicate_headers.each do |header|
      errors << "Duplicate column headers: The header #{header} should occur only once."
    end
    errors.empty?
  end

  private

  def duplicate_headers
    @headers.group_by { |e| e }.filter { |_k, v| v.count > 1 }.keys
  end
end
