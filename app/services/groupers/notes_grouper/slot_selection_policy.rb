# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Notes selection policy:
    # - if there is exactly one matching tuple in the description, use first slot
    # - otherwise choose first slot not already assigned in this description
    class SlotSelectionPolicy
      def initialize(token_match_counter:)
        @token_match_counter = token_match_counter
      end

      def call(slots:, token:, slot_mapping:, **)
        if token_match_counter.count(token) == 1
          slots.first
        else
          slots.find { |slot| !slot_mapping.value?(slot) }
        end
      end

      private

      attr_reader :token_match_counter
    end
  end
end
