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
class NotesGrouper
  def self.group(descriptions:)
    new(descriptions:).group
  end

  def initialize(descriptions:)
    @descriptions = descriptions
    # Grab labels and types early, before any mutation happens, and put the note
    # label and type values in order from most ubiquitous to least. Why? This
    # way leftmost columns will be more populated, with less used values
    # pushed to the right.
    @ordered_mapping = SeedMappingBuilder.new(descriptions).build
  end

  def group
    descriptions.transform_values do |description|
      DescriptionRewriter.new(description: description, ordered_mapping: ordered_mapping).rewrite!
    end
  end

  private

  attr_reader :descriptions, :ordered_mapping

  class NoteToken
    def self.from_description(description, prefix)
      [description["#{prefix}.displayLabel"], description["#{prefix}.type"]]
    end

    def self.from_grouped_hash(hash, num)
      [hash["old_note#{num}.displayLabel"], hash["old_note#{num}.type"]]
    end

    def self.from_ungrouped_hash(hash, num)
      [hash["note#{num}.displayLabel"], hash["note#{num}.type"]]
    end
  end

  class DescriptionRewriter
    def initialize(description:, ordered_mapping:)
      @description = description
      @ordered_mapping = ordered_mapping
      @slot_allocator = SlotAllocator.new(description: description, ordered_mapping: ordered_mapping)
    end

    def rewrite!
      # Build up a description-specific mapping as a way to track for the current description
      # how we are mapping old note elements to new ones.
      mapping = {}

      # First, we rename all the note header values, e.g., "note1.type" to "old_note1.type"
      # so that we can track which values have already been changed, else we get collisions and are
      # unable to distinguish already grouped data from yet-to-be-grouped data.
      description.transform_keys! do |key|
        key.match?(/^note\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end

      description.transform_keys! do |key|
        # Short-circuit by returning the key unchanged if not note-related.
        note_number = key.match(/^old_note(\d+)/)
        next key unless note_number

        # If we already have a description-specific mapping for the note_number
        # being operated on, use it and move on
        if mapping.key?(note_number[0])
          next key.sub(/^old_note\d+/, mapping[note_number[0]])
        end

        # Get the displayLabel and type values of the note number corresponding to the key currently being transformed
        note_token = NoteToken.from_description(description, "old_note#{note_number[1]}")
        label_for_note_number, type_for_note_number = note_token

        new_note_number = slot_allocator.allocate(
          key: key,
          note_token: note_token,
        )

        # Fall back to original number if look-up returned nil
        new_note_number ||= "note#{note_number[1]}"

        # Extend the description-specific mapping with the above information
        mapping[note_number[0]] = new_note_number

        # Map the current "old" note number element to the new one.
        key.sub(/^old_note\d+/, new_note_number)
      end

      description
    end

    private

    attr_reader :description, :ordered_mapping, :slot_allocator
  end

  class SlotAllocator
    def initialize(description:, ordered_mapping:)
      @description = description
      @ordered_mapping = ordered_mapping
    end

    def allocate(key:, note_token:)
      case matching_note_tuple_count(note_token)
      when 1
        # If there is only one matching note number in the mapping, use it and move on.
        ordered_mapping.key(note_token)
      else
        # If there are multiple notes of this type, e.g., an
        # item with multiple notes of type "abstract" with a
        # nil display label, use the first note number not
        # already used.
        # Also applies when there are no displayLabels or types for the note
        ordered_mapping.find do |mapped_note_number, mapped_note_token|
          mapped_note_token == note_token &&
            !description.key?(key.sub(/^old_note\d+/, mapped_note_number))
        end&.first
      end
    end

    private

    attr_reader :description, :ordered_mapping

    def matching_note_tuple_count(note_token)
      description.slice(*description.keys.grep(/note.+(displayLabel|type)/))
        .group_by { |k, _v| k.match(/(.*note\d+)\./)[1] }
        .count { |_key, value| tuple_matches?(value, note_token) }
    end

    def tuple_matches?(value, note_token)
      hash = value.to_h
      num = hash.keys.first[/\d+/]
      NoteToken.from_grouped_hash(hash, num) == note_token ||
        NoteToken.from_ungrouped_hash(hash, num) == note_token
    end
  end

  class SeedMappingBuilder
    def initialize(descriptions)
      @descriptions = descriptions
    end

    def build
      label_and_type_values = descriptions.values.map do |description|
        notes_count = description.keys.grep(/^note\d+\./).max_by { |field| field[/\d+/].to_i }
        next if notes_count.nil?

        1.upto(notes_count[/\d+/].to_i).map do |note_number|
          NoteToken.from_description(description, "note#{note_number}")
        end
      end

      return {} unless label_and_type_values.any?

      # Order based on frequency of a given tuple
      unique_types_in_order = label_and_type_values
                              .flatten(1)
                              .index_with { |note_type| label_and_type_values.flatten(1).count(note_type) }
                              .sort_by { |_value, count| -count }
                              .to_h
                              .keys

      repeat_types_counts = {}
      label_and_type_values
        .map { |row| row&.select { |field| row.count(field) > 1 } }
        .compact_blank
        .each do |repeats|
          repeat_types_counts.merge!(
            repeats.index_with { |e| repeats.count(e) }
          )
        end

      repeat_types_counts.each do |value, count|
        unique_types_in_order.insert(unique_types_in_order.index(value), *Array.new(count - 1) { value })
      end

      unique_types_in_order.map.with_index(1).to_h { |key, index| ["note#{index}", key] }
    end

    private

    attr_reader :descriptions
  end
end
