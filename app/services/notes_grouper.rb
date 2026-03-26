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
  PREFIX = 'note'

  def self.group(descriptions:)
    new(descriptions:).group
  end

  def initialize(descriptions:)
    @descriptions = descriptions
    # Grab labels and types early, before any mutation happens, and put the note
    # label and type values in order from most ubiquitous to least. Why? This
    # way leftmost columns will be more populated, with less used values
    # pushed to the right.
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
      DescriptionRewriter.new(description: description, ordered_mapping: ordered_mapping).rewrite!
    end
  end

  private

  def rows
    descriptions.values.map do |description|
      notes_count = description.keys.grep(/^note\d+\./).max_by { |field| field[/\d+/].to_i }
      next if notes_count.nil?

      1.upto(notes_count[/\d+/].to_i).map do |note_number|
        NoteToken.from_description(description, "note#{note_number}").to_key
      end
    end
  end

  def unique_order_strategy
    ->(computed_rows) do
      computed_rows
        .flatten(1)
        .index_with { |token| computed_rows.flatten(1).count(token) }
        .sort_by { |_value, count| -count }
        .to_h
        .keys
    end
  end

  def repeat_counts_strategy
    ->(computed_rows) do
      repeat_types_counts = {}
      computed_rows
        .map { |row| row&.select { |field| row.count(field) > 1 } }
        .compact_blank
        .each do |repeats|
        repeat_types_counts.merge!(
          repeats.index_with { |e| repeats.count(e) }
        )
      end
      repeat_types_counts
    end
  end

  def expand_strategy
    ->(unique, repeats) do
      expanded = unique.dup
      repeats.each do |value, count|
        expanded.insert(expanded.index(value), *Array.new(count - 1) { value })
      end
      expanded
    end
  end

  attr_reader :descriptions, :ordered_mapping

  class NoteToken
    attr_reader :display_label, :type

    def self.from_description(description, prefix)
      new(
        display_label: description["#{prefix}.displayLabel"],
        type: description["#{prefix}.type"]
      )
    end

    def self.from_grouped_hash(hash, num)
      new(
        display_label: hash["old_note#{num}.displayLabel"],
        type: hash["old_note#{num}.type"]
      )
    end

    def self.from_ungrouped_hash(hash, num)
      new(
        display_label: hash["note#{num}.displayLabel"],
        type: hash["note#{num}.type"]
      )
    end

    def initialize(display_label:, type:)
      @display_label = display_label
      @type = type
    end

    def to_key
      [display_label, type]
    end

    def ==(other)
      other.is_a?(NoteToken) && to_key == other.to_key
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
      # Build up a description-specific mapping as a way to track for the current description
      # how we are mapping old note elements to new ones.
      slot_mapping = {}

      # First, we rename all the note header values, e.g., "note1.type" to "old_note1.type"
      # so that we can track which values have already been changed, else we get collisions and are
      # unable to distinguish already grouped data from yet-to-be-grouped data.
      description.transform_keys! do |key|
        key.match?(/^note\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end

      description.transform_keys! do |key|
        # Short-circuit by returning the key unchanged if not note-related.
        number = extract_old_number(key)
        next key unless number

        old_prefix = "old_#{prefix_name}#{number}"

        # If we already have a description-specific mapping for the note_number
        # being operated on, use it and move on
        if slot_mapping.key?(old_prefix)
          next replace_old_prefix(key, slot_mapping[old_prefix])
        end

        token = token_for(number: number)

        # Get the displayLabel and type values of the note number corresponding to the key currently being transformed
        new_prefix = allocate_slot(key: key, token: token, slot_mapping: slot_mapping)

        # Extend the description-specific mapping with the above information
        slot_mapping[old_prefix] = new_prefix

        # Map the current "old" note number element to the new one.
        replace_old_prefix(key, new_prefix)
      end

      description
    end

    private

    attr_reader :description, :ordered_mapping, :slot_allocator

    def extract_old_number(key)
      match = key.match(/^old_note(\d+)/)
      match && match[1]
    end

    def replace_old_prefix(key, prefix)
      key.sub(/^old_note\d+/, prefix)
    end

    def token_for(number:)
      NoteToken.from_description(description, "old_#{prefix_name}#{number}")
    end

    def allocate_slot(key:, token:, slot_mapping:)
      # Fall back to original number if look-up returned nil
      slot_allocator.allocate(
        key: key,
        token: token,
        slot_mapping: slot_mapping
      ) || "#{prefix_name}#{extract_old_number(key)}"
    end

    def prefix_name
      'note'
    end
  end

  class SlotAllocator
    def initialize(description:, ordered_mapping:)
      @description = description
      @ordered_mapping = ordered_mapping
    end

    def allocate(key:, token:, slot_mapping:)
      slots = matching_slots_for(token)

      # If there is only one matching note number in the mapping, use it and move on.
      # ordered_mapping.key(token.to_key)
      return slots.first if matching_note_tuple_count(token) == 1

      # If there are multiple notes of this type, e.g., an
      # item with multiple notes of type "abstract" with a
      # nil display label, use the first note number not
      # already used.
      # Also applies when there are no displayLabels or types for the note
      # ordered_mapping.find do |mapped_note_number, mapped_note_tuple|
      #   mapped_note_tuple == token.to_key &&
      #     !slot_mapping.value?(mapped_note_number)
      # end&.first
      slots.find do |mapped_note_number|
        !slot_mapping.value?(mapped_note_number)
      end
    end

    private

    attr_reader :description, :ordered_mapping

    def matching_slots_for(token)
      ordered_mapping.select { |_slot, mapped_note_tuple| mapped_note_tuple == token.to_key }.keys
    end

    # no-op for parity
    def append_slot(token)
      # max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
      # new_note = "note#{max + 1}"
      # ordered_mapping[new_note] = token.to_key
      # new_note
    end

    def matching_note_tuple_count(token)
      description.slice(*description.keys.grep(/note.+(displayLabel|type)/))
        .group_by { |k, _v| k.match(/(.*note\d+)\./)[1] }
        .count { |_key, value| tuple_matches?(value, token) }
    end

    def tuple_matches?(value, token)
      hash = value.to_h
      num = hash.keys.first[/\d+/]

      NoteToken.from_grouped_hash(hash, num) == token ||
        NoteToken.from_ungrouped_hash(hash, num) == token
    end
  end

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
