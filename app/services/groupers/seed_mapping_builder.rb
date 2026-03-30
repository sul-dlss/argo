# frozen_string_literal: true

module Groupers
  # Shared seed-map pipeline used by both groupers.
  #
  # Each grouper provides:
  # - rows extraction
  # - unique ordering strategy
  # - repeat counting strategy
  # - expansion strategy
  #
  # Required strategy contracts
  # - unique_order_strategy: (rows) -> unique ordered tokens
  # - repeat_counts_strategy: (rows) -> { token => repeat_count }
  # - expand_strategy: (unique, repeats) -> expanded list
  class SeedMappingBuilder
    # @param prefix [String]
    # @param rows [Array<Array<Object>>]
    # @param unique_order_strategy [#call]
    # @param repeat_counts_strategy [#call]
    # @param expand_strategy [#call]
    # @return [Hash{String => Object}]
    #   Canonical seed slot mapping, e.g. {"form1" => token, ...}.
    def self.build(...)
      new(...).build
    end

    # @param prefix [String]
    # @param rows [Array<Array<Object>>]
    # @param unique_order_strategy [#call]
    # @param repeat_counts_strategy [#call]
    # @param expand_strategy [#call]
    # @return [void]
    def initialize(prefix:, rows:, unique_order_strategy:, repeat_counts_strategy:, expand_strategy:)
      @prefix = prefix.to_s
      @rows = rows
      @unique_order_strategy = unique_order_strategy
      @repeat_counts_strategy = repeat_counts_strategy
      @expand_strategy = expand_strategy
    end

    # @return [Hash{String => String}]
    #   Canonical seed slot mapping for the provided prefix and strategies.
    def build
      return {} if rows.empty?

      unique = unique_order_strategy.call(rows)
      repeats = repeat_counts_strategy.call(rows)
      expanded = expand_strategy.call(unique, repeats)

      expanded.map.with_index(1).to_h { |token, i| ["#{prefix}#{i}", token] }
    end

    private

    # @return [String]
    attr_reader :prefix

    # @return [Array<Array<Object>>]
    attr_reader :rows

    # @return [#call]
    attr_reader :unique_order_strategy

    # @return [#call]
    attr_reader :repeat_counts_strategy

    # @return [#call]
    attr_reader :expand_strategy
  end
end
