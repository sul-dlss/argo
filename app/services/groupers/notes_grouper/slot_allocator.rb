# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Notes slot allocation policy:
    # - Use existing seeded note slots for the token.
    # - Selection is tuple-count-sensitive (single match vs multiple matches).
    # - Do not append slots here; when no slot is chosen, return nil and let
    #   TokenMappingRewriter fall back to the original note number.
    #   This preserves legacy notes grouping behavior.
    #
    # Notes matching is tuple-aware and count-sensitive.
    class SlotAllocator
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @token_match_counter = TokenMatchCounter.new(description:)
        @pipeline = SlotAllocationPipeline.new(
          slots_for: method(:slots_for),
          choose_existing: SlotSelectionPolicy.new(token_match_counter:).method(:call),
          fallback: method(:fallback_slot_for)
        )
      end

      delegate :allocate, to: :pipeline

      private

      attr_reader :description, :ordered_mapping, :pipeline, :match_counter, :token_match_counter

      def slots_for(token)
        ordered_mapping.select { |_slot, mapped_token| mapped_token == token.to_key }.keys
      end

      # Notes fallback behavior is intentionally nil.
      # TokenMappingRewriter then falls back to the original note number
      # (e.g., note3 stays note3 when no canonical slot is selected).
      #
      # This differs intentionally from forms, which appends slots.
      def fallback_slot_for(**)
        nil
      end
    end
  end
end
