# frozen_string_literal: true

# Convert CSV to a hash
class ImportTagsCsvConverter
  # @param [String] csv_string CSV string
  # @return [Hash] a hash of druids and associated tags to import
  def self.convert(csv_string:)
    new(csv_string: csv_string).convert
  end

  # @param [String] csv_string CSV string
  def initialize(csv_string:)
    @csv_string = csv_string
  end

  # @return [Hash<String,Array<String>>] a hash of druids and tag arrays to import
  def convert
    # NOTE: Enumerable#filter_map was added in Ruby 2.7
    CSV.parse(csv_string).filter_map do |druid, *tags|
      [prefix_if_missing(druid), tags.compact] if druid.present?
    end.to_h
  end

  private

  attr_reader :csv_string

  def prefix_if_missing(druid)
    return druid if druid.start_with?('druid:')

    "druid:#{druid}"
  end
end
