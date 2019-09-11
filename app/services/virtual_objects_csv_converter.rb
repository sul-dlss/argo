# frozen_string_literal: true

# Convert CSV to JSON for virtual objects
class VirtualObjectsCsvConverter
  def self.convert(csv_string:)
    new(csv_string: csv_string).convert
  end

  attr_reader :csv_string

  # @param [String] csv_string CSV string
  def initialize(csv_string:)
    @csv_string = csv_string
  end

  # @return [Hash] a virtual_objects hash suitable for passing off to dor-services-client
  def convert
    rows = CSV.parse(csv_string)

    virtual_objects = rows.map(&:compact).map do |row|
      {
        parent_id: row.first,
        child_ids: row.drop(1)
      }
    end

    { virtual_objects: virtual_objects }
  end
end
