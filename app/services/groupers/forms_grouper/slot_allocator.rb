# frozen_string_literal: true

module Groupers
  class FormsGrouper
    # Forms slot allocation policy:
    # - Prefer an existing matching slot that is not yet used in this description
    #   and does not collide with already-present key paths.
    # - If no existing slot is suitable, append a new slot to the global mapping.
    #   This allows the form mapping to evolve as previously unseen shapes appear.
    #
    # (This differs intentionally from NotesGrouper::SlotAllocator behavior.)
    class SlotAllocator
      # @param description [Hash{String => String}]
      # @param ordered_mapping [Hash{String => (String, nil)}]
      # @return [void]
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @pipeline = SlotAllocationPipeline.new(
          slots_for: method(:slots_for),
          choose_existing: SlotSelectionPolicy.new(description:).method(:call),
          fallback: method(:fallback_slot_for)
        )
      end

      # @param token [Token]
      # @param key [String]
      # @param slot_mapping [Hash{String => String}]
      # @return [String]
      #   Canonical slot selected for this token.
      delegate :allocate, to: :pipeline

      private

      # @return [Hash{String => String}]
      attr_reader :description

      # @return [Hash{String => (String, nil)}]
      attr_reader :ordered_mapping

      # @return [SlotAllocationPipeline]
      attr_reader :pipeline

      # @param token [Token]
      # @return [Array<String>]
      #   Canonical slots currently mapped to this token key.
      def slots_for(token)
        ordered_mapping.select { |_slot, mapped_token| mapped_token == token.to_key }.keys
      end

      # Forms fallback behavior is to expand the global slot map.
      # This differs intentionally from notes fallback behavior.
      #
      # @param token [Token]
      # @return [String]
      #   Newly appended canonical form slot.
      def fallback_slot_for(token:, **)
        append_slot_for(token)
      end

      # @param token [Token]
      # @return [String]
      #   Newly appended canonical form slot.
      def append_slot_for(token)
        max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
        new_form = "#{PREFIX}#{max + 1}"
        ordered_mapping[new_form] = token.to_key
        new_form
      end
    end
  end
end
