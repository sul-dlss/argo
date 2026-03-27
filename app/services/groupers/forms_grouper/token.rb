# frozen_string_literal: true

module Groupers
  class FormsGrouper
    # Value object representing the semantic identity of a form entry.
    # For forms, type is primary; value is fallback when type is absent.
    class Token
      attr_reader :value, :type

      def self.from_description(description, prefix)
        new(
          value: description["#{prefix}.value"],
          type: description["#{prefix}.type"]
        )
      end

      delegate :hash, to: :to_key

      def initialize(value:, type:)
        @value = value
        @type = type
      end

      def to_key
        type || value
      end

      def ==(other)
        other.is_a?(Token) && to_key == other.to_key
      end
      alias eql? ==
    end
  end
end
