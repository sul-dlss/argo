# frozen_string_literal: true

# For grouping note attributes, we list the unique note display label and type
# values and their counts in the descriptions and put them in descending count
# order (most frequent note labels/types first, least frequent last), and
# resulting in a mapping of note numbers to note labels/types, e.g.:
#
# {"note1"=>[nil, "abstract"], "note2"=>["Provenance", "ownership"]}
#
# We expand this mapping as we examine more descriptions in the set, e.g., if a record has multiple
# notes w/ a nil display label and type "abstract", the above mapping would expand to:
#
# {"note1"=>[nil, "abstract"], "note2"=>[nil, "abstract"], "note3"=>["Provenance", "ownership"]}
#
# We then use this mapping to group all given descriptions.
#
# NOTE: This class is tested in the context of the DescriptionsGrouper
module Groupers
  # Groups flattened note fields into stable semantic note slots (note1, note2, ...).
  #
  # Pipeline:
  # 1) Build ordered seed mapping from note token rows.
  # 2) Rewrite each description against canonical note slots.
  class NotesGrouper
    PREFIX = 'note'

    # @param descriptions [Hash<String, Hash{String => String}>]
    #   Mapping of druid => flattened description hash.
    # @return [Hash<String, Hash{String => String}>]
    #   Mapping of druid => grouped flattened description hash.
    def self.group(descriptions:)
      new(descriptions:).group
    end

    # @param descriptions [Hash<String, Hash{String => String}>]
    # @return [void]
    def initialize(descriptions:)
      @descriptions = descriptions
      # Grab labels and types early, before any mutation happens, and put the note
      # label and type values in order from most ubiquitous to least. Why? This
      # way leftmost columns will be more populated, with less used values
      # pushed to the right.
      @ordered_mapping = SeedMappingBuilder.build(
        prefix: PREFIX,
        rows:,
        unique_order_strategy: method(:unique_order_strategy),
        repeat_counts_strategy: method(:repeat_counts_strategy),
        expand_strategy: method(:expand_strategy)
      )
    end

    # @return [Hash<String, Hash{String => String}>]
    #   Mapping of druid => grouped flattened description hash.
    def group
      descriptions.transform_values do |description|
        DescriptionRewriter.new(description:, ordered_mapping:).rewrite!
      end
    end

    private

    # Builds per-description rows for seed mapping.
    #
    # Each row is the ordered list of note tokens [displayLabel, type]
    # found in one description.
    #
    # @return [Array<Array<Array(String, nil)>>]
    def rows
      descriptions.values.map do |description|
        notes_count = description.keys
                                 .grep(/^#{PREFIX}\d+\./o)
                                 .max_by { |field| field[/\d+/].to_i }
        next if notes_count.nil?

        1.upto(notes_count[/\d+/].to_i).map do |note_number|
          Token.from_description(description, "#{PREFIX}#{note_number}").to_key
        end
      end
    end

    # Orders unique note tokens by descending frequency.
    #
    # @param computed_rows [Array<Array<Array(String, nil)>>]
    # @return [Array<Array(String, nil)>]
    def unique_order_strategy(computed_rows)
      flat = computed_rows.flatten(1)

      counts = Hash.new(0)
      first_seen = {}

      flat.each_with_index do |token, idx|
        counts[token] += 1
        first_seen[token] ||= idx
      end

      counts.keys.sort_by do |token|
        [
          -counts[token],      # most frequent first
          first_seen[token]    # preserve first-seen ordering on ties
        ]
      end
    end

    # Computes max repeat count for each token across rows.
    #
    # @param computed_rows [Array<Array<Array(String, nil)>>]
    # @return [Hash{Array(String, nil) => Integer}]
    def repeat_counts_strategy(computed_rows)
      {}.tap do |repeat_types_counts|
        computed_rows.each do |row|
          next if row.blank?

          repeats_for_row = row.tally.select { |_token, count| count > 1 }
          repeat_types_counts.merge!(repeats_for_row)
        end
      end
    end

    # Expands each token by repeat count, preserving adjacency of repeated tokens.
    #
    # @param unique [Array<Array(String, nil)>]
    # @param repeats [Hash{Array(String, nil) => Integer}]
    # @return [Array<Array(String, nil)>]
    def expand_strategy(unique, repeats)
      unique.dup.tap do |expanded|
        repeats.each do |value, count|
          expanded.insert(expanded.index(value), *Array.new(count - 1) { value })
        end
      end
    end

    # @return [Hash<String, Hash{String => String}>]
    # @!visibility private
    attr_reader :descriptions

    # @return [Hash{String => Array(String, nil)}]
    # @!visibility private
    attr_reader :ordered_mapping
  end
end
