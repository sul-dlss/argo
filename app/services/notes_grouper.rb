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
      pipeline.allocate(token: token, key: key, slot_mapping: slot_mapping)
    end

    private

    attr_reader :description, :ordered_mapping, :pipeline

    def matching_slots_for(token)
      ordered_mapping.select { |_slot, mapped_note_tuple| mapped_note_tuple == token.to_key }.keys
    end

    def choose_from_existing_slots(slots:, token:, key:, slot_mapping:)
      if matching_note_tuple_count(token) == 1
        # If there is only one matching note number in the mapping, use it and move on.
        slots.first
      else
        # If there are multiple notes of this type, use the first note number not already used.
        # Also applies when there are no displayLabels or types for the note
        slots.find { |mapped_note_number| !slot_mapping.value?(mapped_note_number) }
      end
    end

    # no-op for parity with Forms pipeline; DescriptionRewriter handles fallback
    def fallback_slot_for(token:, key:, slot_mapping:)
      nil
    end

    # kept for parity, intentionally unused right now
    def append_slot(token)
      max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
      new_note = "note#{max + 1}"
      ordered_mapping[new_note] = token.to_key
      new_note
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

  class SlotAllocationPipeline
    def initialize(matching_slots:, choose_existing:, fallback:)
      @matching_slots = matching_slots
      @choose_existing = choose_existing
      @fallback = fallback
    end

    def allocate(token:, key:, slot_mapping:)
      slots = matching_slots.call(token)
      chosen = choose_existing.call(
        slots: slots,
        token: token,
        key: key,
        slot_mapping: slot_mapping
      )
      chosen || fallback.call(token: token, key: key, slot_mapping: slot_mapping)
    end

    private

    attr_reader :matching_slots, :choose_existing, :fallback
  end

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
      TokenMappingRewriter.new(
        description: description,
        prefix_name: 'note',
        token_for: method(:token_for),
        allocate_slot: method(:allocate_slot)
      ).rewrite!
    end

    private

    attr_reader :description, :ordered_mapping, :slot_allocator

    def token_for(number:)
      NoteToken.from_description(description, "old_note#{number}")
    end

    def allocate_slot(key:, token:, slot_mapping:)
      slot_allocator.allocate(key: key, token: token, slot_mapping: slot_mapping)
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

  class TokenMappingRewriter
    def initialize(description:, prefix_name:, token_for:, allocate_slot:)
      @description = description
      @prefix_name = prefix_name
      @token_for = token_for
      @allocate_slot = allocate_slot
    end

    def rewrite!
      slot_mapping = {}

      rename_prefixes!

      description.transform_keys! do |key|
        number = extract_old_number(key)
        next key unless number

        old_prefix = "old_#{prefix_name}#{number}"

        slot_mapping[old_prefix] ||= begin
                                       token = token_for.call(number: number)
                                       allocate_slot.call(key: key, token: token, slot_mapping: slot_mapping) || "#{prefix_name}#{number}"
                                     end

        replace_old_prefix(key, slot_mapping[old_prefix])
      end

      description
    end

    private

    attr_reader :description, :prefix_name, :token_for, :allocate_slot

    def rename_prefixes!
      description.transform_keys! do |key|
        key.match?(/^#{prefix_name}\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key
      end
    end

    def extract_old_number(key)
      match = key.match(/^old_#{prefix_name}(\d+)/)
      match && match[1]
    end

    def replace_old_prefix(key, prefix)
      key.sub(/^old_#{prefix_name}\d+/, prefix)
    end
  end
end
