# frozen_string_literal: true

module Groupers
  # Shared allocation flow:
  #
  # 1) compute candidate slots for token
  # 2) choose existing slot via policy
  # 3) fallback via policy if none chosen
  #
  # Policies are injected to keep grouper-specific behavior explicit.
  class SlotAllocationPipeline
    def initialize(slots_for:, choose_existing:, fallback:)
      @slots_for = slots_for
      @choose_existing = choose_existing
      @fallback = fallback
    end

    def allocate(token:, key:, slot_mapping:)
      slots = slots_for.call(token)
      choose_existing.call(slots:, token:, key:, slot_mapping:) ||
        fallback.call(token:, key:, slot_mapping:)
    end

    private

    attr_reader :slots_for, :choose_existing, :fallback
  end
end
