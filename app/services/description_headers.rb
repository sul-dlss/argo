# frozen_string_literal: true

# Creates column headers for descriptive metadata exports
class DescriptionHeaders
  def self.create(headers:)
    new(headers:).create
  end

  def initialize(headers:)
    @headers = headers
  end

  def create
    headers.sort_by do |header|
      [
        # First sort by the root property sort order
        sort_order.index(field_name(header)) || headers.length,
        # Followed by sorting within a root property (title1 before title2, title10 after title9)
        header.split(".").first[/\d+/].to_i,
        # Then sort on properties below the root, first using the alpha
        # characters of the property then on the numeric component if present
        *header.split(".").drop(1).flat_map { |field| [field[/\D+/], field[/\d+/].to_i] }
      ]
    end
  end

  private

  attr_reader :headers

  def field_name(key)
    # This regex matches root properties without any trailing indices.
    #
    # Root properties consist only of alphabetical characters and underscores
    # (for source_id, in particular, which is a header we depend on being
    # present.
    /(?<root_property>[[[:alpha:]]_]*)/.match(key)[:root_property]
  end

  def sort_order
    %w[source_id title contributor form event language note identifier access purl subject relatedResource adminMetadata geographic marcEncodedData valueAt]
  end
end
