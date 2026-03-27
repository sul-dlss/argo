# frozen_string_literal: true

module Groupers
  # Shared rewrite engine for flattened tokenized fields.
  #
  # Responsibilities:
  # 1) temporarily rename prefixN.* -> old_prefixN.* to avoid key collisions
  # 2) compute one slot mapping per old_prefixN within a description
  # 3) rewrite old_prefixN.* keys to canonical prefixM.* keys
  class TokenMappingRewriter
    def initialize(description:, prefix_name:, token_for:, allocate_slot:)
      @description = description
      @prefix_name = prefix_name
      @token_for = token_for
      @allocate_slot = allocate_slot
    end

    # Per-description mapping of old_prefixN => canonical prefixM.
    # This ensures all fields for the same token move together.
    def rewrite!
      slot_mapping = {}

      rename_prefixes!

      description.transform_keys! do |key|
        number = extract_old_number(key)
        next key unless number

        old_prefix = "old_#{prefix_name}#{number}"

        unless slot_mapping.key?(old_prefix)
          # Shared fallback point: if allocator returns nil, retain original
          # column number for this prefix family.
          token = token_for.call(number: number)
          slot_mapping[old_prefix] = allocate_slot.call(key: key, token: token, slot_mapping: slot_mapping) || "#{prefix_name}#{number}"
        end

        replace_old_prefix(key, slot_mapping[old_prefix])
      end

      description
    end

    private

    attr_reader :description, :prefix_name, :token_for, :allocate_slot

    def rename_prefixes!
      description.transform_keys! do |key|
        key.match?(/^#{prefix_name}\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end
    end

    def extract_old_number(key)
      match = key.match(/^old_#{prefix_name}(\d+)/)
      match && match[1]
    end

    def replace_old_prefix(key, prefix)
      key.sub(/^old_#{prefix_name}\d+/, prefix)
    end
  end
end
