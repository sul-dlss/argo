# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Notes selection policy:
    # - if there is exactly one matching tuple in the description, use first slot
    # - otherwise choose first slot not already assigned in this description
    class SlotSelectionPolicy
      # @param token_match_counter [TokenMatchCounter]
      # @return [void]
      def initialize(token_match_counter:)
        @token_match_counter = token_match_counter
      end

      # @param slots [Array<String>]
      #   Candidate canonical note slots (e.g., ["note1", "note3"]).
      # @param token [Token]
      #   Semantic note token for the current old note prefix.
      # @param slot_mapping [Hash{String => String}]
      #   Per-description mapping of old prefixes to canonical slots.
      # @return [String, nil]
      #   Chosen canonical slot, if one is available.
      def call(slots:, token:, slot_mapping:, **)
        if token_match_counter.count(token) == 1
          slots.first
        else
          slots.find { |slot| !slot_mapping.value?(slot) }
        end
      end

      private

      # @return [TokenMatchCounter]
      attr_reader :token_match_counter
    end
  end
end
