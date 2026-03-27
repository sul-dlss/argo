# frozen_string_literal: true

module Groupers
  # Orchestrates grouping for flattened description exports.
  #
  # Processing order:
  # 1) forms are grouped into canonical form slots
  # 2) notes are grouped into canonical note slots
  class DescriptionsGrouper
    # @param descriptions [Hash<String, Hash{String => String}>]
    #   Mapping of druid => flattened description hash.
    # @return [Hash<String, Hash{String => String}>]
    #   Mapping of druid => grouped flattened description hash.
    def self.group(descriptions:)
      new(descriptions:).group
    end

    # @param descriptions [Hash<String, Hash{String => String}>]
    #   Mapping of druid => flattened description hash.
    # @return [void]
    def initialize(descriptions:)
      @descriptions = descriptions
    end

    # Groups all provided descriptions by canonical form and note slots.
    #
    # @return [Hash<String, Hash{String => String}>]
    #   Mapping of druid => grouped flattened description hash.
    def group
      descriptions
        .then { |descs| FormsGrouper.group(descriptions: descs) }
        .then { |descs| NotesGrouper.group(descriptions: descs) }
    end

    private

    # @return [Hash<String, Hash{String => Object}>]
    attr_reader :descriptions
  end
end
