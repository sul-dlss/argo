# frozen_string_literal: true

# Reads and normalizes a CSV that is uploaded as part of Bulk Actions.
class CsvUploadNormalizer
  def self.read(...)
    new(...).read
  end

  # @param path [String] path to uploaded file
  # @param druid_headers [Array<String>] headers that contain druids
  # @param remove_columns_without_headers [Boolean] whether to remove columns without headers
  # @param remove_preamble_rows [Boolean] whether to remove rows that appear before the header row
  def initialize(path, druid_headers: %w[Druid druid], remove_columns_without_headers: false, remove_preamble_rows: false)
    @path = path
    @druid_headers = druid_headers
    @remove_columns_without_headers = remove_columns_without_headers
    @remove_preamble_rows = remove_preamble_rows
  end

  # Reads uploaded file (could be csv or Excel) and normalizes to CSV.
  # This includes handling BOM and druids without prefixes.
  # @return [String] csv
  # @raise [StandardError] if unsupported file type
  # @raise [CSV::MalformedCSVError] if malformed CSV, e.g., invalid byte sequence
  def read
    raise 'Unsupported upload file type' unless %w[.csv .ods .xls .xlsx].include? File.extname(path)

    spreadsheet = Roo::Spreadsheet.open(path, { csv_options: { encoding: 'bom|utf-8' } }) # open the spreadsheet
    csv = spreadsheet.to_csv
    csv = remove_preamble(csv) if remove_preamble_rows
    table = CSV.parse(csv, headers: true) # convert spreadsheet to CSV and then parse by the CSV library

    remove_columns_without_headers!(table) if remove_columns_without_headers
    normalize_druids!(table)
    table.to_csv
  end

  private

  attr_reader :path, :druid_headers, :remove_columns_without_headers, :remove_preamble_rows

  def remove_preamble(csv)
    lines = csv.split("\n")
    lines.shift until lines.first&.match?(/^"?#{druid_headers.join('|')}/) || lines.empty?
    return csv if lines.empty?

    lines.join("\n")
  end

  def remove_columns_without_headers!(table)
    table.by_col!
    table.delete(nil) while table.headers.include?(nil)
    table.by_row!
  end

  def normalize_druids!(table)
    table.each do |row|
      druid_headers.each { |header| row[header] = Druid.new(row[header].strip).with_namespace if row[header].present? }
    end
  end
end
