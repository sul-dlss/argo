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
  # Groups flattened form fields into stable semantic form slots (form1, form2, ...).
  # Seed mapping is computed once per batch; each description is then rewritten
  # against that mapping.
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
        unique_order_strategy: method(:unique_order_strategy),
        repeat_counts_strategy: method(:repeat_counts_strategy),
        expand_strategy: method(:expand_strategy)
      )
    end

    def group
      descriptions.transform_values do |description|
        DescriptionRewriter.new(description:, ordered_mapping:).rewrite!
      end
    end

    private

    def rows
      descriptions.values.map do |description|
        description
          .keys
          .grep(/\A#{PREFIX}\d+\.type\z/o)
          .sort_by { |key| key[/\d+/].to_i }
          .map { |key| description[key] }
      end
    end

    def unique_order_strategy(computed_rows)
      computed_rows
        .flatten
        .tally
        .sort_by { |_type, count| -count }
        .map(&:first)
    end

    def repeat_counts_strategy(computed_rows)
      Hash.new(1).tap do |max_repeats|
        computed_rows.each do |row|
          row.tally.each do |type, count|
            max_repeats[type] = [max_repeats[type], count].max
          end
        end
      end
    end

    def expand_strategy(unique, repeats)
      [].tap do |expanded|
        unique.each do |type|
          repeats[type].times { expanded << type }
        end
      end
    end

    attr_reader :descriptions, :ordered_mapping
  end
end
