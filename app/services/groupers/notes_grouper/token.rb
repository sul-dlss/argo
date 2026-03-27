# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Value object representing the semantic identity of a note entry.
    #
    # For notes, identity is [displayLabel, type].
    class Token
      # @return [String, nil]
      attr_reader :display_label

      # @return [String, nil]
      attr_reader :type

      # Builds a token from a flattened description hash and a note prefix.
      #
      # @param description [Hash{String => String}]
      # @param prefix [String] e.g., "note1" or "old_note1"
      # @return [Token]
      def self.from_description(description, prefix)
        new(
          display_label: description["#{prefix}.displayLabel"],
          type: description["#{prefix}.type"]
        )
      end

      # Builds a token from grouped hash fields in rewritten (`old_noteN.*`) form.
      #
      # @param hash [Hash{String => String}]
      # @param num [String]
      # @return [Token]
      def self.from_grouped_hash(hash, num)
        new(
          display_label: hash["old_#{PREFIX}#{num}.displayLabel"],
          type: hash["old_#{PREFIX}#{num}.type"]
        )
      end

      # Builds a token from grouped hash fields in original (`noteN.*`) form.
      #
      # @param hash [Hash{String => String}]
      # @param num [String]
      # @return [Token]
      def self.from_ungrouped_hash(hash, num)
        new(
          display_label: hash["#{PREFIX}#{num}.displayLabel"],
          type: hash["#{PREFIX}#{num}.type"]
        )
      end

      # @param display_label [String, nil]
      # @param type [String, nil]
      # @return [void]
      def initialize(display_label:, type:)
        @display_label = display_label
        @type = type
      end

      # Semantic key used for slot matching.
      #
      # @return [Array<(String, nil)>]
      def to_key
        [display_label, type]
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
