# frozen_string_literal: true

module Groupers
  class FormsGrouper
    # Value object representing the semantic identity of a form entry.
    #
    # For forms, type is primary; value is used as a fallback identity when type is absent.
    class Token
      # @return [String, nil]
      attr_reader :value

      # @return [String, nil]
      attr_reader :type

      # Builds a token from a flattened description hash and a form prefix.
      #
      # @param description [Hash{String => String}]
      # @param prefix [String] e.g., "form1" or "old_form1"
      # @return [Token]
      def self.from_description(description, prefix)
        new(
          value: description["#{prefix}.value"],
          type: description["#{prefix}.type"]
        )
      end

      # @param value [String, nil]
      # @param type [String, nil]
      # @return [void]
      def initialize(value:, type:)
        @value = value
        @type = type
      end

      # Semantic key used for slot matching.
      #
      # @return [String, nil]
      def to_key
        type || value
      end

      # @param other [Object]
      # @return [Boolean]
      def ==(other)
        other.is_a?(Token) && to_key == other.to_key
      end
      alias eql? ==

      # @return [Integer]
      delegate :hash, to: :to_key
    end
  end
end
