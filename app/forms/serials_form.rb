# frozen_string_literal: true

class SerialsForm < ApplicationChangeSet
  property :part_number, virtual: true
  property :part_name, virtual: true
  property :part_number2, virtual: true
  property :sort_field, virtual: true

  PART_NAME = 'part name'
  PART_NUMBER = 'part number'
  MAIN_TITLE = 'main title'
  PRIMARY = 'primary'
  NOTE_TYPE = 'date/sequential designation'

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    titles = model.description.title
    title_to_change = titles.find { |title| title.status == PRIMARY }
    title_to_change ||= titles.first

    setup_from_structured_value(title_to_change.structuredValue) if title_to_change.structuredValue.present?
    self.sort_field = title_to_change.note.find { |note| note.type == NOTE_TYPE }&.value
  end

  def setup_from_structured_value(structured_value)
    part_name_index = structured_value.index { |element| element.type == PART_NAME }
    part_number_index = structured_value.index { |element| element.type == PART_NUMBER }
    part_number_value = structured_value.find { |element| element.type == PART_NUMBER }&.value
    if part_number_value && part_number_index < part_name_index
      self.part_number = part_number_value
    else
      self.part_number2 = part_number_value
    end
    self.part_name = structured_value.find { |element| element.type == PART_NAME }&.value
  end

  def save_model
    updated_description = model.description.new(title: updated_title)
    updated_model = model.new(description: updated_description)
    object_client.update(params: updated_model)
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def updated_title
    # Convert to hash so we can mutate.
    model.description.title.map(&:to_h).tap do |titles|
      title_to_change = titles.find { |title| title[:status] == PRIMARY }
      title_to_change ||= titles.first
      title_to_change[:note].delete_if { |note| note[:type] == NOTE_TYPE }
      title_to_change[:note] << { type: NOTE_TYPE, value: sort_field } if sort_field.present?
      title_to_change[:structuredValue] = update_or_create_structured_value(title_to_change)
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
    structured_value << { value: part_number, type: PART_NUMBER } if part_number.present?
    structured_value << { value: part_name, type: PART_NAME } if part_name.present?
    structured_value << { value: part_number2, type: PART_NUMBER } if part_number2.present?
    structured_value
  end

  def create_structured_value_from_unstructured(unstructured)
    [{ value: unstructured.delete(:value), type: MAIN_TITLE }].tap do |structured_value|
      structured_value << { value: part_number, type: PART_NUMBER } if part_number.present?
      structured_value << { value: part_name, type: PART_NAME } if part_name.present?
      structured_value << { value: part_number2, type: PART_NUMBER } if part_number2.present?
    end
  end
end
