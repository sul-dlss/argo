# frozen_string_literal: true

module Groupers
  # Shared seed-map orchestration.
  #
  # Each grouper provides:
  # - rows extraction
  # - unique ordering strategy
  # - repeat counting + expansion strategy
  #
  # Required strategy contracts:
  # - unique_order_strategy: (rows) -> unique ordered tokens
  # - repeat_counts_strategy: (rows) -> { token => repeat_count }
  # -_expand_strategy: (unique, repeats) -> expanded token list
  class SeedMappingBuilder
    def self.build(...)
      new(...).build
    end

    def initialize(prefix:, rows:, unique_order_strategy:, repeat_counts_strategy:, expand_strategy:)
      @prefix = prefix.to_s
      @rows = rows
      @unique_order_strategy = unique_order_strategy
      @repeat_counts_strategy = repeat_counts_strategy
      @expand_strategy = expand_strategy
    end

    def build
      return {} if rows.empty?

      unique = unique_order_strategy.call(rows)
      repeats = repeat_counts_strategy.call(rows)
      expanded = expand_strategy.call(unique, repeats)

      expanded.map.with_index(1).to_h { |token, i| ["#{prefix}#{i}", token] }
    end

    private

    attr_reader :prefix, :rows, :unique_order_strategy, :repeat_counts_strategy, :expand_strategy
  end
end
