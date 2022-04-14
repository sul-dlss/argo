# frozen_string_literal: true

# Creates column headers for descriptive metadata exports
class DescriptionHeaders
  def self.create(headers:)
    new(headers: headers).create
  end

  def initialize(headers:)
    @headers = headers
  end

  def create
    sort_order = %w[title contributor form event language note identifier access purl subject relatedResource adminMetadata geographic marcEncodedData valueAt]
    updated_headers = (@headers - ['source_id']).sort
    ['source_id'] + updated_headers.sort_by.with_index { |header, index| [sort_order.index(field_name(header)) || headers.length, index] }
  end

  private

  def field_name(key)
    /[[:alpha:]]*/.match(key)[0]
  end
end
