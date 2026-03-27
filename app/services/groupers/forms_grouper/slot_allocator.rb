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
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @pipeline = SlotAllocationPipeline.new(
          slots_for: method(:slots_for),
          choose_existing: SlotSelectionPolicy.new(description:).method(:call),
          fallback: method(:fallback_slot_for)
        )
      end

      delegate :allocate, to: :pipeline

      private

      attr_reader :description, :ordered_mapping, :pipeline

      def slots_for(token)
        ordered_mapping.select { |_slot, mapped_token| mapped_token == token.to_key }.keys
      end

      # Forms fallback behavior is to expand the global slot map.
      # This differs intentionally from notes fallback behavior.
      def fallback_slot_for(token:, **)
        append_slot_for(token)
      end

      def append_slot_for(token)
        max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
        new_form = "#{PREFIX}#{max + 1}"
        ordered_mapping[new_form] = token.to_key
        new_form
      end
    end
  end
end
