# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Rewrites one flattened description hash from old_noteN.* to canonical noteN.* slots.
    #
    # Delegates slot-choice behavior to SlotAllocator while using
    # TokenMappingRewriter for the shared remapping mechanics.
    class DescriptionRewriter
      # @param description [Hash{String => String}]
      # @param ordered_mapping [Hash{String => Array(String, nil)>}]
      # @return [void]
      def initialize(description:, ordered_mapping:)
        @description = description
        @slot_allocator = SlotAllocator.new(description:, ordered_mapping:)
      end

      # @return [Hash{String => String}]
      #   The same hash instance with keys rewritten to canonical note slots.
      def rewrite!
        TokenMappingRewriter.new(
          description:,
          prefix_name: PREFIX,
          token_for: method(:token_for),
          slot_allocator:
        ).rewrite!
      end

      private

      # @return [Hash{String => String}]
      attr_reader :description

      # @return [SlotAllocator]
      attr_reader :slot_allocator

      # @param number [String]
      # @return [Token]
      def token_for(number:)
        Token.from_description(description, "old_#{PREFIX}#{number}")
      end
    end
  end
end
