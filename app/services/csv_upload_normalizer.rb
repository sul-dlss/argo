# frozen_string_literal: true

# Reads and normalizes a CSV that is uploaded as part of Bulk Actions.
class CsvUploadNormalizer
  SUPPORTED_FILE_EXTENSIONS = %w[.csv .ods .xls .xlsx].freeze

  def self.read(...)
    new(...).read
  end

  # @param path [String] path to uploaded file
  def initialize(path)
    @path = path
  end

  # Reads uploaded file (could be csv or Excel) and normalizes to CSV.
  # This includes handling BOM and druids without prefixes.
  # @return [String] csv
  # @raise [StandardError] if unsupported file type
  # @raise [CSV::MalformedCSVError] if malformed CSV, e.g., invalid byte sequence
  def read # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    raise 'Unsupported upload file type' unless normalized_file_extension.in?(SUPPORTED_FILE_EXTENSIONS)

    # If handed *anything but* a CSV file, first pre-process into a CSV string with Roo.
    csv_string = normalized_file_extension == '.csv' ? normalized_csv_string : Roo::Spreadsheet.open(path).to_csv

    # Deal with both pre-processed CSV strings or files, using the built-in CSV
    # library to parse either.
    table = CSV.parse(csv_string, headers: true, skip_blanks: true, skip_lines: /^\s*$/,
                                  converters: whitespace_only_nullifier).tap do |csv|
      # Remove rows that are a bunch of nils
      csv.by_row!.delete_if { |row| row.fields.none? }

      # Remove columns that lack a header (e.g., if the header row winds up with
      # any repeated commas in it)
      csv.by_col!.delete_if { |(column, *)| column.nil? }

      # Normalize the druids in the druid column, if present, to have the 'druid:' prefix
      csv.headers.find { |header| header.match?(/\Adruid\z/i) }.tap do |druid_column|
        next if druid_column.nil?

        csv[druid_column] = csv[druid_column].map { |druid| Druid.new(druid).with_namespace if druid.present? }
      end
    end

    table.to_csv
  rescue ArgumentError => e
    raise CSV::MalformedCSVError.new(e, 'CSV could not be opened due to an encoding error')
  end

  private

  attr_reader :path

  def normalized_file_extension
    @normalized_file_extension ||= File.extname(path).downcase
  end

  # This method:
  #
  # 1. Removes the BOM if present (since CSV.parse will not)
  # 2. Ignores any preamble lines before the legitimate header row
  # 3. Removes line feeds at the end of lines (`CSV#parse` wants newlines)
  def normalized_csv_string
    csv = File.read(path, encoding: 'bom|utf-8')
    lines = csv.split(/\r?\n/)
    lines.shift until lines.first&.match?(/\Adruid,/i) || lines.empty?
    return csv if lines.empty?

    lines.join("\n")
  end

  def whitespace_only_nullifier
    ->(field) { field&.strip.presence }
  end
end
