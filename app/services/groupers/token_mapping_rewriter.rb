# frozen_string_literal: true

module Groupers
  # Shared key-rewrite engine.
  #
  # Input: flattened hash with prefix-indexed keys (e.g., form1.value, note2.type).
  # Output: same hash with canonicalized slot prefixes.
  # Guarantees:
  # - all fields for one old_prefixN move together to one target slot
  # - unrelated keys remain unchanged
  #
  # Responsibilities:
  # 1) temporarily rename prefixN.* -> old_prefixN.* to avoid key collisions
  # 2) compute one slot mapping per old_prefixN within a description
  # 3) rewrite old_prefixN.* keys to canonical prefixM.* keys
  class TokenMappingRewriter
    def initialize(description:, prefix_name:, token_for:, slot_allocator:)
      @description = description
      @prefix_name = prefix_name
      @token_for = token_for
      @slot_allocator = slot_allocator
    end

    # Per-description mapping of old_prefixN => canonical prefixM.
    # This ensures all fields for the same token move together.
    def rewrite! # rubocop:disable Metrics/CyclomaticComplexity
      slot_mapping = {}

      # Rename prefixes on the first pass to avoid collisions during mapping.
      # This allows us to compute all slot mappings first, then rewrite keys in
      # one pass.
      description.transform_keys! do |key|
        key.match?(/^#{prefix_name}\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end

      description.transform_keys! do |key|
        number = (match = key.match(/^old_#{prefix_name}(\d+)/)) && match[1]
        next key unless number

        old_prefix = "old_#{prefix_name}#{number}"

        unless slot_mapping.key?(old_prefix)
          # Shared fallback point: if allocator returns nil, retain original
          # column number for this prefix family.
          token = token_for.call(number:)
          slot_mapping[old_prefix] = slot_allocator.allocate(key:, token:, slot_mapping:) || "#{prefix_name}#{number}"
        end

        key.sub(/^old_#{prefix_name}\d+/, slot_mapping[old_prefix])
      end

      description
    end

    private

    attr_reader :description, :prefix_name, :token_for, :slot_allocator
  end
end
