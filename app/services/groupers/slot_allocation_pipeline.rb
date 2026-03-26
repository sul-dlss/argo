# frozen_string_literal: true

module Groupers
  class SlotAllocationPipeline
    def initialize(matching_slots:, choose_existing:, fallback:)
      @matching_slots = matching_slots
      @choose_existing = choose_existing
      @fallback = fallback
    end

    def allocate(token:, key:, slot_mapping:)
      slots = matching_slots.call(token)
      chosen = choose_existing.call(
        slots: slots,
        token: token,
        key: key,
        slot_mapping: slot_mapping
      )
      chosen || fallback.call(token: token, key: key, slot_mapping: slot_mapping)
    end

    private

    attr_reader :matching_slots, :choose_existing, :fallback
  end
end
