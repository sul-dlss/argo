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

      def self.from_grouped_hash(hash, num)
        new(
          value: hash["old_form#{num}.value"],
          type: hash["old_form#{num}.type"]
        )
      end

      def self.from_ungrouped_hash(hash, num)
        new(
          value: hash["form#{num}.value"],
          type: hash["form#{num}.type"]
        )
      end

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

      def eql?(...)
        self.==(...)
      end

      delegate :hash, to: :to_key
    end
  end
end
