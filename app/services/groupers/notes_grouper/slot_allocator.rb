# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Notes slot allocation policy:
    # - Use existing seeded note slots for the token.
    # - Selection is tuple-count-sensitive (single match vs multiple matches).
    # - Do not append slots here; when no slot is chosen, return nil and let
    #   TokenMappingRewriter fall back to the original note number.
    #   This preserves legacy notes grouping behavior.
    class SlotAllocator
      # @param description [Hash{String => String}]
      # @param ordered_mapping [Hash{String => Array(String, nil)>}]
      # @return [void]
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @match_counter = TokenMatchCounter.new(description:)
        @pipeline = SlotAllocationPipeline.new(
          slots_for: method(:slots_for),
          choose_existing: SlotSelectionPolicy.new(token_match_counter: match_counter).method(:call),
          fallback: method(:fallback_slot_for)
        )
      end

      # @param token [Token]
      # @param key [String]
      # @param slot_mapping [Hash{String => String}]
      # @return [String, nil]
      #   Canonical slot selected for this token, or nil if no slot is selected.
      delegate :allocate, to: :pipeline

      private

      # @return [Hash{String => String}]
      attr_reader :description

      # @return [Hash{String => Array(String, nil)>}]
      attr_reader :ordered_mapping

      # @return [TokenMatchCounter]
      attr_reader :match_counter

      # @return [SlotAllocationPipeline]
      attr_reader :pipeline

      # @param token [Token]
      # @return [Array<String>]
      #   Canonical slots currently mapped to this token key.
      def slots_for(token)
        ordered_mapping.select { |_slot, mapped_token| mapped_token == token.to_key }.keys
      end

      # Notes fallback behavior is intentionally nil.
      # TokenMappingRewriter then falls back to the original note number
      # (e.g., note3 stays note3 when no canonical slot is selected).
      #
      # This differs intentionally from forms, which appends slots.
      #
      # @return [nil]
      def fallback_slot_for(**)
        nil
      end
    end
  end
end
