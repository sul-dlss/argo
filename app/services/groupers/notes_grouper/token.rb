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
          display_label: hash["old_note#{num}.displayLabel"],
          type: hash["old_note#{num}.type"]
        )
      end

      def self.from_ungrouped_hash(hash, num)
        new(
          display_label: hash["note#{num}.displayLabel"],
          type: hash["note#{num}.type"]
        )
      end

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

      def eql?(...)
        self.==(...)
      end

      def hash
        to_key.hash
      end
    end
  end
end
