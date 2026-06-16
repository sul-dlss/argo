# frozen_string_literal: true

# Reads and normalizes a CSV that is uploaded as part of Bulk Actions.
class CsvUploadNormalizer
  SUPPORTED_FILE_EXTENSIONS = %w[.csv .ods .xls .xlsx].freeze
  DRUID_HEADER = 'druid'

  def self.read(...)
    new(...).read
  end

  # @param path [String] path to uploaded file
  def initialize(path, remove_blank_columns: true)
    @path = path
    @remove_blank_columns = remove_blank_columns
  end

  attr_reader :remove_blank_columns

  # Reads uploaded file (could be csv or Excel) and normalizes to CSV.
  # This includes handling BOM and druids without prefixes.
  # @return [String] csv
  # @raise [StandardError] if unsupported file type
  # @raise [CSV::MalformedCSVError] if malformed CSV, e.g., invalid byte sequence
  def read # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    raise 'Unsupported upload file type' unless normalized_file_extension.in?(SUPPORTED_FILE_EXTENSIONS)

    # Cleanup and normalize the CSV data
    table = normalized_csv_data.tap do |csv|
      # Remove rows that are a bunch of nils
      csv.by_row!.delete_if { |row| row.fields.none? }

      # Remove columns that lack a header (e.g., if the header row winds up with
      # any repeated commas in it)
      csv.by_col!.delete_if { |(column, *)| column.nil? } if remove_blank_columns

      # Normalize the druids in the druid column, if present, to have the 'druid:' prefix
      csv.headers.compact.find { |header| header.match?(/\Adruid\z/i) }.tap do |druid_column|
        next if druid_column.nil?

        csv.by_col!
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

  # Given raw CSV data from normalized_csv_file remove any preamble
  # rows before the proper header row based on DRUID_HEADER
  #
  # @return [CSV:Table] the imported CSV data with headers
  def normalized_csv_data
    raw = normalized_csv_file

    # Find the first row that starts with DRUID_HEADER
    druid_index = raw.index { |line| line.first.casecmp?(DRUID_HEADER) }

    # DROP all preamble rows leading up to the proper header row
    csv_string = CSV.generate do |csv|
      raw[druid_index..].map { |row| csv << row }
    end

    CSV.parse(csv_string, headers: true)
  end

  # This method:
  #
  # 1. Reads a CSV with the standard library if the extention is CSV
  # 2. Otherwise reads the file with ROO and parses into a CSV
  # @return [Array] an array of rows in a CSV file
  def normalized_csv_file
    return CSV.read(path, skip_blanks: true, converters: whitespace_only_nullifier) if normalized_file_extension == '.csv'

    # If handed *anything but* a CSV file, first pre-process into a CSV string with Roo.
    CSV.parse(Roo::Spreadsheet.open(path).to_csv, skip_blanks: true, skip_lines: /^\s*$/,
                                                  converters: whitespace_only_nullifier)
  end

  def whitespace_only_nullifier
    ->(field) { field&.strip.presence }
  end
end
