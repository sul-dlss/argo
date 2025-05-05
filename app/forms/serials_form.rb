# frozen_string_literal: true

class SerialsForm < ApplicationChangeSet
  property :part_label, virtual: true
  property :sort_key, virtual: true

  validates :part_label, presence: true, if: -> { sort_key.present? }

  PART_NAME = 'part name'
  PART_NUMBER = 'part number'
  MAIN_TITLE = 'main title'
  PRIMARY = 'primary'
  NOTE_TYPE = 'date/sequential designation'

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    self.part_label = model.identification&.catalogLinks&.find { |link| link.catalog == 'folio' }&.partLabel ||
                      part_label_from_titles
    self.sort_key = model.identification&.catalogLinks&.find { |link| link.catalog == 'folio' }&.sortKey ||
                    model.description.note.find { |note| note.type == NOTE_TYPE }&.value
  end

  def part_label_from_titles # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    title_to_change = model.description.title.find { |title| title.status == PRIMARY } ||
                      model.description.title.first

    return unless (structured_title = structured_title_for_setup(title_to_change))

    part_name = structured_title.find { |element| element.type == PART_NAME }&.value
    part_parts = [part_name]
    part_number, part_number_position = setup_part_number(structured_title)

    if part_number_position == :before
      part_parts.prepend(part_number)
    elsif part_number_position == :after
      part_parts.append(part_number)
    end

    part_parts.compact.join(', ')
  end

  def structured_title_for_setup(title)
    return title.structuredValue if title.structuredValue.present?
    return title.parallelValue.first.structuredValue if title.parallelValue.first&.structuredValue

    nil
  end

  def setup_part_number(structured_title)
    part_number_value = structured_title.find { |element| element.type == PART_NUMBER }&.value

    return [nil, nil] if part_number_value.nil?

    part_number_index = structured_title.index { |element| element.type == PART_NUMBER }
    part_name_index = structured_title.index { |element| element.type == PART_NAME }

    position = part_name_index && part_number_index > part_name_index ? :after : :before

    [part_number_value, position]
  end

  def save_model
    updated_model = model.new(description: updated_description, identification: updated_identification)
    Repository.store(updated_model)
  end

  def updated_description
    model.description.new(title: updated_title, note: updated_note)
  end

  def updated_title
    # Convert to hash so we can mutate.
    model.description.title.map(&:to_h).tap do |titles|
      title_to_change = titles.find { |title| title[:status] == PRIMARY } || titles.first
      if title_to_change[:parallelValue].present?
        title_to_change[:parallelValue].first[:structuredValue] =
          update_or_create_structured_value(title_to_change[:parallelValue].first)
      else
        title_to_change[:structuredValue] = update_or_create_structured_value(title_to_change)
      end
    end
  end

  def updated_note
    # Convert to hash so we can mutate.
    model.description.note.map(&:to_h).tap do |notes|
      notes.delete_if { |note| note[:type] == NOTE_TYPE }
      notes << { type: NOTE_TYPE, value: sort_key } if sort_key.present?
    end
  end

  def update_or_create_structured_value(title_to_change)
    # If the existing title value is a structuredValue:
    #   Remove any values in the structured value with type “part name” or “part number”.
    #   Add the new part name/number values to the structuredValue with the appropriate type in the order in which they were entered.
    return update_structured_value(title_to_change[:structuredValue]) if title_to_change[:structuredValue].present?

    # If the existing title value is an unstructured value:
    #   1. Change the title entry to a structuredValue with the existing title value as the first element, with type “main title”.
    #   2. Add the new part name/number values to the structuredValue with the appropriate type in the order in which they were entered.
    create_structured_value_from_unstructured(title_to_change)
  end

  def update_structured_value(structured_value)
    structured_value.delete_if { |element| [PART_NAME, PART_NUMBER].include?(element[:type]) }
    structured_value << { value: part_label, type: PART_NAME } if part_label.present?
    structured_value
  end

  def create_structured_value_from_unstructured(unstructured)
    [{ value: unstructured.delete(:value), type: MAIN_TITLE }].tap do |structured_value|
      structured_value << { value: part_label, type: PART_NAME } if part_label.present?
    end
  end

  def updated_identification
    model.identification.new(catalogLinks: updated_catalog_links)
  end

  def updated_catalog_links
    model.identification.catalogLinks.map do |catalog_link|
      catalog_link_hash = catalog_link.to_h

      if catalog_link_hash[:catalog] == 'folio'
        catalog_link_hash[:partLabel] = part_label
        catalog_link_hash[:sortKey] = sort_key
      end

      catalog_link_hash.merge(refresh: false)
    end
  end
end
