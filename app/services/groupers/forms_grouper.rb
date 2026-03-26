# frozen_string_literal: true

# For grouping form attributes, we list the unique form type values
# and their counts in the descriptions and put them in descending count
# order (most frequent form types first, least frequent last), and resulting
# in a mapping of form numbers to form types, e.g.:
#
# {"form1"=>"digital origin", "form2"=>"extent", "form3"=>"form", "form4"=>"resource type", "form5"=>"genre"}
#
# We expand this mapping as we examine more descriptions in the set, e.g., if a record has multiple
# forms of type "resource type", the above mapping might expand to:
#
# {"form1"=>"digital origin", "form2"=>"extent", "form3"=>"form", "form4"=>"resource type", "form5"=>"genre", "form6"=>"resource type"}
#
# We then use this mapping to group all given descriptions.
#
# NOTE: This class is tested in the context of the DescriptionsGrouper
module Groupers
  class FormsGrouper
    PREFIX = 'form'

    def self.group(descriptions:)
      new(descriptions:).group
    end

    def initialize(descriptions:)
      @descriptions = descriptions
      @ordered_mapping = SeedMappingBuilder.build(
        prefix: PREFIX,
        rows:,
        unique_order_strategy:,
        repeat_counts_strategy:,
        expand_strategy:
      )
    end

    def group
      descriptions.transform_values do |description|
        DescriptionRewriter.new(
          description: description,
          ordered_mapping: ordered_mapping
        ).rewrite!
      end
    end

    private

    def rows
      descriptions.values.map do |description|
        description.keys
          .grep(/\Aform\d+\.type\z/)
          .sort_by { |k| k[/\d+/].to_i }
          .map { |k| description[k] }
      end
    end

    def unique_order_strategy
      ->(computed_rows) do
        computed_rows
          .flatten
          .tally
          .sort_by { |_type, count| -count }
          .map(&:first)
      end
    end

    def repeat_counts_strategy
      ->(computed_rows) do
        max_repeats = Hash.new(1)
        computed_rows.each do |row|
          row.tally.each do |type, count|
            max_repeats[type] = [max_repeats[type], count].max
          end
        end
        max_repeats
      end
    end

    def expand_strategy
      ->(unique, repeats) do
        expanded = []
        unique.each do |type|
          repeats[type].times { expanded << type }
        end
        expanded
      end
    end

    attr_reader :descriptions, :ordered_mapping

    class FormToken
      attr_reader :value, :type

      def self.from_description(description, prefix)
        new(
          value: description["#{prefix}.value"],
          type: description["#{prefix}.type"]
        )
      end

      def self.from_grouped_hash(hash, num)
        new(
          value: hash["old_form#{num}.value"],
          type: hash["old_form#{num}.type"]
        )
      end

      def self.from_ungrouped_hash(hash, num)
        new(
          value: hash["form#{num}.value"],
          type: hash["form#{num}.type"]
        )
      end

      def initialize(value:, type:)
        @value = value
        @type = type
      end

      def to_key
        type || value
      end

      def ==(other)
        other.is_a?(FormToken) && to_key == other.to_key
      end

      def eql?(...)
        self.==(...)
      end

      def hash
        to_key.hash
      end
    end

    class DescriptionRewriter
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @slot_allocator = SlotAllocator.new(description: description, ordered_mapping: ordered_mapping)
      end

      def rewrite!
        TokenMappingRewriter.new(
          description: description,
          prefix_name: 'form',
          token_for: method(:token_for),
          allocate_slot: method(:allocate_slot)
        ).rewrite!
      end

      private

      attr_reader :description, :ordered_mapping, :slot_allocator

      def token_for(number:)
        FormToken.from_description(description, "old_form#{number}")
      end

      def allocate_slot(key:, token:, slot_mapping:)
        slot_allocator.allocate(key: key, token: token, slot_mapping: slot_mapping)
      end
    end

    class SlotAllocator
      def initialize(description:, ordered_mapping:)
        @description = description
        @ordered_mapping = ordered_mapping
        @pipeline = SlotAllocationPipeline.new(
          matching_slots: method(:matching_slots_for),
          choose_existing: method(:choose_from_existing_slots),
          fallback: method(:fallback_slot_for)
        )
      end

      def allocate(key:, token:, slot_mapping:)
        pipeline.allocate(token: token, slot_mapping: slot_mapping, key: key)
      end

      private

      attr_reader :description, :ordered_mapping, :pipeline

      def matching_slots_for(token)
        ordered_mapping.select { |_slot, mapped_token| mapped_token == token.to_key }.keys
      end

      def choose_from_existing_slots(slots:, token:, key:, slot_mapping:)
        slots.find do |mapped_form_number|
          next false if slot_mapping.value?(mapped_form_number)

          remapped_key = key.sub(/\Aold_form\d+/, mapped_form_number)
          !description.key?(remapped_key)
        end
      end

      def fallback_slot_for(token:, key:, slot_mapping:)
        append_slot(token)
      end

      def append_slot(token)
        max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
        new_form = "form#{max + 1}"
        ordered_mapping[new_form] = token.to_key
        new_form
      end
    end
  end
end
