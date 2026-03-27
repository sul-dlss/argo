# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Rewrites one flattened description hash from old_noteN.* to canonical noteN.* slots.
    # Delegates slot-choice policy to SlotAllocator.
    class DescriptionRewriter
      def initialize(description:, ordered_mapping:)
        @description = description
        @slot_allocator = SlotAllocator.new(description: description, ordered_mapping: ordered_mapping)
      end

      def rewrite!
        TokenMappingRewriter.new(
          description: description,
          prefix_name: PREFIX,
          token_for: method(:token_for),
          allocate_slot: method(:allocate_slot)
        ).rewrite!
      end

      private

      attr_reader :description, :slot_allocator

      def token_for(number:)
        Token.from_description(description, "old_note#{number}")
      end

      def allocate_slot(key:, token:, slot_mapping:)
        slot_allocator.allocate(key: key, token: token, slot_mapping: slot_mapping)
      end
    end
  end
end
