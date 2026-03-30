# frozen_string_literal: true

module Groupers
  class FormsGrouper
    # Forms selection policy:
    # choose the first candidate slot that is not already assigned in this
    # description and does not collide with an existing key path.
    class SlotSelectionPolicy
      # @param description [Hash{String => String}]
      # @return [void]
      def initialize(description:)
        @description = description
      end

      # @param slots [Array<String>]
      #   Candidate canonical form slots (e.g., ["form1", "form4"]).
      # @param key [String]
      #   Current key being transformed (e.g., "old_form2.value").
      # @param slot_mapping [Hash{String => String}]
      #   Per-description mapping of old prefixes to canonical slots.
      # @return [String, nil]
      #   Chosen canonical slot, if one is available.
      def call(slots:, key:, slot_mapping:, **)
        slots.find do |slot|
          next false if slot_mapping.value?(slot)

          remapped_key = key.sub(/\Aold_#{PREFIX}\d+/o, slot)
          !description.key?(remapped_key)
        end
      end

      private

      # @return [Hash{String => String}]
      attr_reader :description
    end
  end
end
