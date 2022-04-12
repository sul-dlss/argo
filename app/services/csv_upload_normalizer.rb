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

  # Reads uploaded file (could be csv or Excel) and normalizes to CSV.
  # This includes handling BOM and druids without prefixes.
  def read
    raise 'Unsupported upload file type' unless %w[.csv .ods .xls .xlsx].include? File.extname(path)

    spreadsheet = Roo::Spreadsheet.open(path, { csv_options: { encoding: 'bom|utf-8' } }) # open the spreadsheet
    table = CSV.parse(spreadsheet.to_csv, headers: true) # convert spreadsheet to CSV and then parse by the CSV library

    table.each do |row|
      druid_headers.each { |header| row[header] = Druid.new(row[header]).with_namespace if row[header].present? }
    end
    table.to_csv
  end

  private

  attr_reader :path, :druid_headers
end
