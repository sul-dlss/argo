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
    @ordered_mapping = SeedMappingBuilder.new(descriptions).build
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

  attr_reader :descriptions, :ordered_mapping

  class SeedMappingBuilder
    def initialize(descriptions)
      @descriptions = descriptions
    end

    def build
      typed_rows = descriptions.values.map { |desc| typed_values_in_form_order(desc) }
      flat = typed_rows.flatten

      unique_in_freq_order = flat.tally.sort_by { |_type, count| -count }.map(&:first)

      max_repeats = Hash.new(1)
      typed_rows.each do |row|
        row.tally.each do |type, count|
          max_repeats[type] = [max_repeats[type], count].max
        end
      end

      expanded = []
      unique_in_freq_order.each do |type|
        max_repeats[type].times { expanded << type }
      end

      expanded.map.with_index(1) { |type, i| ["form#{i}", type] }.to_h
    end

    private

    attr_reader :descriptions

    def typed_values_in_form_order(description)
      description.keys
                 .grep(/\Aform\d+\.type\z/)
                 .sort_by { |k| k[/\d+/].to_i }
                 .map { |k| description[k] }
    end
  end

  class DescriptionRewriter
    def initialize(description:, ordered_mapping:)
      @description = description
      @allocator = SlotAllocator.new(description: description, ordered_mapping: ordered_mapping)
    end

    def rewrite!
      local_map = {}

      rename_to_old_prefixes!

      description.transform_keys! do |key|
        old_form = old_form_prefix(key)
        next key unless old_form

        target = local_map[old_form] ||= allocator.allocate(old_form, key)
        key.sub(/\Aold_form\d+/, target)
      end

      description
    end

    private

    attr_reader :description, :allocator

    def rename_to_old_prefixes!
      description.transform_keys! { |k| k.sub(/\A(form\d+)/, 'old_\1') }
    end

    def old_form_prefix(key)
      m = key.match(/\Aold_form(\d+)/)
      return unless m

      "old_form#{m[1]}"
    end
  end

  class SlotAllocator
    def initialize(description:, ordered_mapping:)
      @description = description
      @ordered_mapping = ordered_mapping
    end

    def allocate(old_form, key_being_transformed)
      token = FormToken.token_for(description, old_form)

      target = first_unused_slot_for_token(token, key_being_transformed)
      return target if target

      append_new_slot(token)
    end

    private

    attr_reader :description, :ordered_mapping

    def first_unused_slot_for_token(token, key_being_transformed)
      ordered_mapping.find do |form_num, mapped_token|
        next false unless mapped_token == token

        remapped_key = key_being_transformed.sub(/\Aold_form\d+/, form_num)
        !description.key?(remapped_key)
      end&.first
    end

    def append_new_slot(token)
      max = ordered_mapping.keys.map { |k| k[/\d+/].to_i }.max || 0
      new_form = "form#{max + 1}"
      ordered_mapping[new_form] = token
      new_form
    end  end

  class FormToken
    def self.token_for(description, old_form)
      description["#{old_form}.type"] || description["#{old_form}.value"]
    end
  end
end
