# frozen_string_literal: true

module Groupers
  # Shared key-rewrite engine for flattened tokenized fields.
  #
  # Responsibilities:
  # 1) temporarily rename prefixN.* => old_prefixN.* to avoid key collisions
  # 2) compute one slot mapping per old_prefixN within a description
  # 3) rewrite old_prefixN.* keys to canonical prefixM.* keys
  class TokenMappingRewriter
    # @param description [Hash{String => String}]
    # @param prefix_name [String]
    #   Canonical field prefix ("form" or "note").
    # @param token_for [#call]
    #   Callable with signature: (number:) -> token.
    # @param slot_allocator [#allocate]
    #   Allocator with signature:
    #   allocate(token:, key:, slot_mapping:) -> String, nil
    # @return [void]
    def initialize(description:, prefix_name:, token_for:, slot_allocator:)
      @description = description
      @prefix_name = prefix_name
      @token_for = token_for
      @slot_allocator = slot_allocator
    end

    # @return [Hash{String => String}]
    #   The same hash instance with rewritten canonical slot prefixes.
    def rewrite!
      # Per-description mapping of old_prefixN => canonical prefixM.
      # This ensures all fields for the same token move together.
      slot_mapping = {}

      rename_prefixes!

      description.transform_keys! do |key|
        number = extract_old_number(key)
        next key unless number

        old_prefix = "old_#{prefix_name}#{number}"

        unless slot_mapping.key?(old_prefix)
          # Shared fallback point: if allocator returns nil, retain original
          # column number for this prefix family.
          token = token_for.call(number:)
          slot_mapping[old_prefix] = slot_allocator.allocate(token:, key:, slot_mapping:) || "#{prefix_name}#{number}"
        end

        replace_old_prefix(key, slot_mapping[old_prefix])
      end

      description
    end

    private

    # @return [Hash{String => String}]
    attr_reader :description

    # @return [String]
    attr_reader :prefix_name

    # @return [#call]
    attr_reader :token_for

    # @return [#allocate]
    attr_reader :slot_allocator

    # Renames target prefixed keys to old_ prefixed keys to avoid collisions
    # during in-place key transformation.
    #
    # @return [void]
    def rename_prefixes!
      description.transform_keys! do |key|
        key.match?(/^#{prefix_name}\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end
    end

    # Extracts the numeric component from keys like old_form3.* or old_note2.*.
    #
    # @param key [String]
    # @return [String, nil]
    def extract_old_number(key)
      match = key.match(/^old_#{prefix_name}(\d+)/)
      match && match[1]
    end

    # Replaces old_ prefixed key root with canonical prefix root.
    #
    # @param key [String]
    # @param prefix [String]
    # @return [String]
    def replace_old_prefix(key, prefix)
      key.sub(/^old_#{prefix_name}\d+/, prefix)
    end
  end
end
