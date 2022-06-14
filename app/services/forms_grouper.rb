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
class FormsGrouper
  def self.group(descriptions:)
    new(descriptions:).group
  end

  def initialize(descriptions:)
    @descriptions = descriptions
    # Grab types early, before any mutation happens, and put the form type values
    # in order from the most ubiquitous value to the least. Why? This way the
    # leftmost columns will be more populated, with less used values pushed to
    # the right.
    @ordered_mapping = ordered_mapping_from(descriptions)
  end

  def group
    descriptions.transform_values do |description|
      # Build up a description-specific mapping as a way to track for the current description
      # how we are mapping old form elements to new ones.
      mapping = {}

      # First, we rename all the form header values, e.g., "form1.source.uri" to "old_form1.source.uri"
      # so that we can track which values have already been changed, else we get collisions and are
      # unable to distinguish already grouped data from yet-to-be-grouped data.
      description.transform_keys! { |key| key.match?(/^form\d+/) ? key.sub(/^(\D+)/, 'old_\1') : key }

      description.transform_keys! do |key|
        # Short-circuit by returning the key unchanged if not form-related.
        next key unless (form_number = key.match(/^old_form(\d+)/))

        # If we already have a description-specific mapping for the form_number
        # being operated on, use it and move on
        next key.sub(/^old_form\d+/, mapping[form_number[0]]) if mapping.key?(form_number[0])

        # Get the type value of the form number corresponding to the key currently being transformed
        type_for_form_number = description.slice(*description.keys.grep(/^old_form#{form_number[1]}\.type/)).values.first

        # Look up the form number of the type value
        new_form_number = case description.slice(*description.keys.grep(/form.+type/)).select { |_key, value| value == type_for_form_number }.count
                          when 0
                            # If there is no matching form number, increment the
                            # current highest form number and use it for form
                            # elements for this type
                            ordered_mapping.max_by { |k, _v| k[/\d+/].to_i }.first.succ.tap do |new_form|
                              ordered_mapping[new_form] = type_for_form_number
                            end
                          when 1
                            # If there is only one matching form number in the mapping, use it and move on.
                            ordered_mapping.key(type_for_form_number)
                          else
                            # If there are multiple forms of this type, e.g., an
                            # item with multiple forms of type "genre", use the
                            # first form number not already used
                            ordered_mapping.find do |mapped_form_number, type_value|
                              type_value == type_for_form_number && !description.key?(key.sub(/^old_form\d+/, mapped_form_number))
                            end&.first
                          end

        # Fall back to original number if look-up returned nil
        new_form_number ||= "form#{form_number[1]}"

        # Extend the description-specific mapping with the above information
        mapping[form_number[0]] = new_form_number

        # Map the current "old" form number element to the new one.
        key.sub(/^old_form\d+/, new_form_number)
      end
    end
  end

  private

  attr_reader :descriptions, :ordered_mapping

  def ordered_mapping_from(descriptions)
    type_values = descriptions.values.map { |description| description.slice(*description.keys.grep(/^form\d+\.type/)).values }
    # e.g.: [
    #         ["genre", "resource type", "form", "extent", "digital origin", "genre"],
    #         ["genre", "resource type", "resource type", "form", "extent", "digital origin"],
    #         ["resource type", "form", "extent", "digital origin"]
    #       ]
    unique_types_in_order = type_values
                            .flatten
                            .index_with { |type| type_values.flatten.count(type) }
                            .sort_by { |_value, count| -count }
                            .to_h
                            .keys

    # ["resource type", "form", "extent", "digital origin", "genre"]
    repeat_types_counts = {}
    type_values
      .map { |row| row&.select { |field| row.count(field) > 1 } }
      .compact_blank
      .each do |repeats|
      repeat_types_counts.merge!(
        repeats.index_with { |e| repeats.count(e) }
      )
    end
    # repeat_types_counts is now:
    #
    # e.g.: {"resource type"=>2, "genre"=>2}
    repeat_types_counts.each do |value, count|
      # Subtract 1 from the repeat types since each already appears once in the types list
      unique_types_in_order.insert(unique_types_in_order.index(value), *Array.new(count - 1) { value })
    end
    # unique_types_in_order is now:
    #
    # ["resource type", "resource type", "form", "extent", "digital origin", "genre", "genre"]
    #
    # What's important here is the repeat keys (multiple resource types and genres) are immediately adjacent
    unique_types_in_order.map.with_index(1).to_h { |key, index| ["form#{index}", key] }
    # {"form1"=>"resource type", "form2"=>"resource type", "form3"=>"form", "form4"=>"extent",
    #  "form5"=>"digital origin", "form6"=>"genre", "form7"=>"genre"}
  end
end
