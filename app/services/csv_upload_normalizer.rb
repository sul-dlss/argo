# frozen_string_literal: true

# Reads and normalizes a CSV that is uploaded as part of Bulk Actions.
class CsvUploadNormalizer
  def self.read(path)
    new(path).read
  end

  def initialize(path, druid_headers: %w[Druid druid])
    @path = path
    @druid_headers = druid_headers
  end

  # Reads and normalizes CSV.
  # This includes handling BOM and druids without prefixes.
  def read
    table = CSV.open(path, 'rb:bom|utf-8', headers: true).read
    table.each do |row|
      druid_headers.each { |header| row[header] = Druid.new(row[header]).with_namespace if row[header].present? }
    end
    table.to_csv
  end

  private

  attr_reader :path, :druid_headers
end
