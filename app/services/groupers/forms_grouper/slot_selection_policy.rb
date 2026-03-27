# frozen_string_literal: true

module Groupers
  class FormsGrouper
    # Forms selection policy:
    # choose the first candidate slot that is not already assigned in this
    # description and does not collide with an existing key path.
    class SlotSelectionPolicy
      def initialize(description:)
        @description = description
      end

      def call(slots:, key:, slot_mapping:, **)
        slots.find do |slot|
          next false if slot_mapping.value?(slot)

          remapped_key = key.sub(/\Aold_#{PREFIX}\d+/o, slot)
          !description.key?(remapped_key)
        end
      end

      private

      attr_reader :description
    end
  end
end
