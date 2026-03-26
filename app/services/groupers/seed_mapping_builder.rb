# frozen_string_literal: true

module Groupers
  class SeedMappingBuilder
    def self.build(...)
      new(...).build
    end

    def initialize(prefix:, rows:, unique_order_strategy:, repeat_counts_strategy:, expand_strategy:)
      @prefix = prefix
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
