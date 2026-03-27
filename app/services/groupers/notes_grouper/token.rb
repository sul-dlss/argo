# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Value object representing the semantic identity of a note entry.
    # For notes, identity is [displayLabel, type].
    class Token
      attr_reader :display_label, :type

      def self.from_description(description, prefix)
        new(
          display_label: description["#{prefix}.displayLabel"],
          type: description["#{prefix}.type"]
        )
      end

      def self.from_grouped_hash(hash, num)
        new(
          display_label: hash["old_#{PREFIX}#{num}.displayLabel"],
          type: hash["old_#{PREFIX}#{num}.type"]
        )
      end

      def self.from_ungrouped_hash(hash, num)
        new(
          display_label: hash["#{PREFIX}#{num}.displayLabel"],
          type: hash["#{PREFIX}#{num}.type"]
        )
      end

      delegate :hash, to: :to_key

      def initialize(display_label:, type:)
        @display_label = display_label
        @type = type
      end

      def to_key
        [display_label, type]
      end

      def ==(other)
        other.is_a?(Token) && to_key == other.to_key
      end
      alias eql? ==
    end
  end
end
