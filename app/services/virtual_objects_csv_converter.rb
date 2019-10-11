# frozen_string_literal: true

# Convert CSV to JSON for virtual objects
class VirtualObjectsCsvConverter
  # @param [String] csv_string CSV string
  # @return [Hash] a virtual_objects hash suitable for passing off to dor-services-client
  def self.convert(csv_string:)
    new(csv_string: csv_string).convert
  end

  attr_reader :csv_string

  # @param [String] csv_string CSV string
  def initialize(csv_string:)
    @csv_string = csv_string
  end

  # @return [Array] an array of virtual_object hashes suitable for passing off to dor-services-client
  def convert
    CSV
      .parse(csv_string) # parses CSV string into an array of rows, each row an array of cell values
      .map(&:compact) # makes sure CSVs with blanks can be processed successfully
      .map { |row| row.map { |pid| pid.start_with?('druid:') ? pid : "druid:#{pid}" } } # prepend "druid:" prefix if absent
      .map { |row| { parent_id: row.first, child_ids: row.drop(1) } } # put in hash shape as required by dor-services-client
  end
end
