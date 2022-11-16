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
    # way the leftmost columns will be more populated, with less used values
    # pushed to the right.
    @ordered_mapping = ordered_mapping_from(descriptions)
  end

  def group
    descriptions.transform_values do |description|
      # Build up a description-specific mapping as a way to track for the current description
      # how we are mapping old note elements to new ones.
      mapping = {}

      # First, we rename all the note header values, e.g., "note1.type" to "old_note1.type"
      # so that we can track which values have already been changed, else we get collisions and are
      # unable to distinguish already grouped data from yet-to-be-grouped data.
      description.transform_keys! { |key| key.match?(/^note\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key }

      description.transform_keys! do |key|
        # Short-circuit by returning the key unchanged if not note-related.
        next key unless (note_number = key.match(/^old_note(\d+)/))

        # If we already have a description-specific mapping for the note_number
        # being operated on, use it and move on
        next key.sub(/^old_note\d+/, mapping[note_number[0]]) if mapping.key?(note_number[0])

        # Get the displayLabel value of the note number corresponding to the key currently being transformed
        label_for_note_number = description.slice(*description.keys.grep(/^old_note#{note_number[1]}\.displayLabel/)).values.first
        # Get the type value of the note number corresponding to the key currently being transformed
        type_for_note_number = description.slice(*description.keys.grep(/^old_note#{note_number[1]}\.type/)).values.first

        # Look up the note number of the [displayLabel, type] tuple value
        new_note_number = case description.slice(*description.keys.grep(/note.+(displayLabel|type)/))
          .group_by { |k, _v| k.match(/(.*note\d+)\./)[1] }
          .count do |_key, value|
                                 hash = value.to_h
                                 num = hash.keys.first[/\d+/]
                                 [hash["old_note#{num}.displayLabel"], hash["old_note#{num}.type"]] == [label_for_note_number, type_for_note_number] ||
                                   [hash["note#{num}.displayLabel"], hash["note#{num}.type"]] == [label_for_note_number, type_for_note_number]
                               end

        when 0
          # If there is no matching note number, increment the
          # current highest note number and use it for note
          # elements for this type
          max_note = ordered_mapping.max_by { |k, _v| k[/\d+/].to_i }.first
          field, number = max_note.scan(/(\D+)(\d+)/).first
          new_note = "#{field}#{number.to_i.succ}"
          ordered_mapping[new_note] = [label_for_note_number, type_for_note_number]
          new_note
        when 1
          # If there is only one matching note number in the mapping, use it and move on.
          ordered_mapping.key([label_for_note_number, type_for_note_number])
        else
          # If there are multiple notes of this type, e.g., an
          # item with multiple notes of type "abstract" with a
          # nil display label, use the first note number not
          # already used
          ordered_mapping.find do |mapped_note_number, (label_value, type_value)|
            [label_value, type_value] == [label_for_note_number, type_for_note_number] && !description.key?(key.sub(/^old_note\d+/, mapped_note_number))
          end&.first
        end

        # Fall back to original number if look-up returned nil
        new_note_number ||= "note#{note_number[1]}"

        # Extend the description-specific mapping with the above information
        mapping[note_number[0]] = new_note_number

        # Map the current "old" note number element to the new one.
        key.sub(/^old_note\d+/, new_note_number)
      end
    end
  end

  private

  attr_reader :descriptions, :ordered_mapping

  def ordered_mapping_from(descriptions)
    label_and_type_values = descriptions
      .values
      .map do |description|
      notes_count = description.keys.grep(/^note\d+\./).max_by { |field| field[/\d+/].to_i }
      next if notes_count.nil?

      1.upto(notes_count[/\d+/].to_i).map do |note_number|
        [
          description["note#{note_number}.displayLabel"],
          description["note#{note_number}.type"]
        ]
      end
    end
    # e.g., when passed a set of six descriptions
    # [
    #   [[nil, "statement of responsibility"], [nil, nil], [nil, "system details"], ["Display label", nil], ["Another label", "condition"], ["Display label", nil]],
    #   [[nil, "abstract"], [nil, nil], [nil, nil], [nil, nil], [nil, "system details"], ["Display label", nil], ["Another label", "condition"]],
    #   [[nil, "abstract"], [nil, "statement of responsibility"], [nil, nil], [nil, nil], [nil, "condition"]],
    #   [[nil, nil], [nil, nil], [nil, nil]],
    #   [[nil, "abstract"], [nil, "date/sequential designation"], [nil, nil]],
    #   [[nil, "abstract"], ["Contents", "table of contents"]]
    # ]
    return {} unless label_and_type_values.any?

    # Order based on frequency of a given tuple
    unique_types_in_order = label_and_type_values
      .flatten(1)
      .index_with { |note_type| label_and_type_values.flatten(1).count(note_type) }
      .sort_by { |_value, count| -count }
      .to_h
      .keys
    # e.g.:
    # [
    #   [nil, nil],
    #   [nil, "abstract"],
    #   ["Display label", nil],
    #   [nil, "statement of responsibility"],
    #   [nil, "system details"],
    #   ["Another label", "condition"],
    #   [nil, "condition"],
    #   [nil, "date/sequential designation"],
    #   ["Contents", "table of contents"]
    # ]

    repeat_types_counts = {}
    label_and_type_values
      .map { |row| row&.select { |field| row.count(field) > 1 } }
      .compact_blank
      .each do |repeats|
      repeat_types_counts.merge!(
        repeats.index_with { |e| repeats.count(e) }
      )
    end
    # e.g.: {["Display label", nil]=>2, [nil, nil]=>3}

    repeat_types_counts.each do |value, count|
      unique_types_in_order.insert(unique_types_in_order.index(value), *Array.new(count - 1) { value })
    end
    # unique_types_in_order is now:
    #
    # [
    #   [nil, nil],
    #   [nil, nil],
    #   [nil, nil],
    #   [nil, "abstract"],
    #   ["Display label", nil],
    #   ["Display label", nil],
    #   [nil, "statement of responsibility"],
    #   [nil, "system details"],
    #   ["Another label", "condition"],
    #   [nil, "condition"],
    #   [nil, "date/sequential designation"],
    #   ["Contents", "table of contents"]
    # ]
    #
    # What's important here is the repeat tuples (e.g., double nils) are immediately adjacent

    unique_types_in_order.map.with_index(1).to_h { |key, index| ["note#{index}", key] }
    # {"note1"=>[nil, nil], "note2"=>[nil, nil], "note3"=>[nil, nil], "note4"=>[nil, "abstract"],
    #  "note5"=>["Display label", nil], "note6"=>["Display label", nil], "note7"=>[nil, "statement of responsibility"],
    #  "note8"=>[nil, "system details"], "note9"=>["Another label", "condition"], "note10"=>[nil, "condition"],
    #  "note11"=>[nil, "date/sequential designation"], "note12"=>["Contents", "table of contents"]}
  end
end
