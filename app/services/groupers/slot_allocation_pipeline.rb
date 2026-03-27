# frozen_string_literal: true

module Groupers
  # Shared allocation flow:
  # 1) compute candidate slots for token
  # 2) choose best existing slot
  # 3) apply grouper-specific fallback when no existing slot is suitable
  #
  # Policies are injected to keep grouper-specific behavior explicit.
  class SlotAllocationPipeline
    # @param slots_for [#call]
    #   Callable with signature: (token) -> Array<String>
    # @param choose_existing [#call]
    #   Callable with signature:
    #   (slots:, token:, key:, slot_mapping:) -> String, nil
    # @param fallback [#call]
    #   Callable with signature:
    #   (token:, key:, slot_mapping:) -> String, nil
    # @return [void]
    def initialize(slots_for:, choose_existing:, fallback:)
      @slots_for = slots_for
      @choose_existing = choose_existing
      @fallback = fallback
    end

    # @param token [Object]
    #   Grouper-specific token value object.
    # @param key [String]
    #   Current key being transformed (e.g., "old_form2.value").
    # @param slot_mapping [Hash{String => String}]
    #   Per-description mapping of old prefixes to canonical slots.
    # @return [String, nil]
    #   Selected canonical slot, or nil if fallback policy returns nil.
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

    # @return [#call]
    attr_reader :slots_for

    # @return [#call]
    attr_reader :choose_existing

    # @return [#call]
    attr_reader :fallback
  end
end
