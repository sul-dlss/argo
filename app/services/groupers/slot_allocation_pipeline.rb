# frozen_string_literal: true

module Groupers
  # Shared allocation flow:
  # 1) compute candidate slots for token
  # 2) choose best existing slot
  # 3) apply grouper-specific fallback when no existing slot is suitable
  class SlotAllocationPipeline
    def initialize(slots_for:, choose_existing:, fallback:)
      @slots_for = slots_for
      @choose_existing = choose_existing
      @fallback = fallback
    end

    def allocate(token:, key:, slot_mapping:)
      slots = slots_for.call(token)
      chosen = choose_existing.call(
        slots: slots,
        token: token,
        key: key,
        slot_mapping: slot_mapping
      )
      chosen || fallback.call(token: token, key: key, slot_mapping: slot_mapping)
    end

    private

    attr_reader :slots_for, :choose_existing, :fallback
  end
end
