# frozen_string_literal: true

# This removes nodes from the generated cocina that we don't want to keep.
# Typically this is for things like a date has a type (e.g. "created"), but no value.
class DescriptionImportFilter
  # @param compacted_params [Hash]
  # @return [Cocina::Model::Description]
  # @raises Cocina::Models::ValidationError
  def self.filter(compacted_params)
    new.filter(compacted_params)

    Cocina::Models::Description.new(compacted_params)
  end

  ATTRIBUTES_TO_FILTER = {
    contributor: :remove_contributors_without_value,
    date: :remove_dates_without_value,
    digitalLocation: :remove_descriptive_values_without_value,
    event: :remove_events_without_value,
    form: :remove_descriptive_values_without_value,
    identifier: :remove_descriptive_values_without_value,
    language: :remove_languages_without_value,
    name: :remove_descriptive_values_without_value,
    note: :remove_notes_without_value,
    structuredValue: :remove_descriptive_values_without_value,
    subject: :remove_descriptive_values_without_value
  }.freeze

  MODELS_WITH_NESTED_ATTRIBUTES = {
    access: Cocina::Models::DescriptiveAccessMetadata,
    adminMetadata: Cocina::Models::DescriptiveAdminMetadata,
    contributor: Cocina::Models::Contributor,
    date: Cocina::Models::DescriptiveValue,
    event: Cocina::Models::Event,
    form: Cocina::Models::DescriptiveValue,
    geographic: Cocina::Models::DescriptiveGeographicMetadata,
    name: Cocina::Models::DescriptiveValue,
    relatedResource: Cocina::Models::RelatedResource,
    structuredValue: Cocina::Models::DescriptiveValue,
    subject: Cocina::Models::DescriptiveValue,
    title: Cocina::Models::DescriptiveValue
  }.freeze

  # recursive, depth first search for incomplete nodes
  def filter(compacted_params, model: Cocina::Models::Description)
    MODELS_WITH_NESTED_ATTRIBUTES.each do |attribute, model|
      case compacted_params[attribute]
      when Hash
        filter(compacted_params[attribute], model:)
      when Array
        compacted_params[attribute].each { |attributes| filter(attributes, model:) }
      end
    end

    ATTRIBUTES_TO_FILTER.each do |attribute, method|
      next unless model.attribute_names.include?(attribute)

      send(method, compacted_params[attribute])
    end

    compacted_params.compact_blank!
  end

  private

  def remove_descriptive_values_without_value(descriptive_values)
    Array(descriptive_values).delete_if { !descriptive_value_sufficient?(it) }
  end

  def remove_notes_without_value(notes)
    Array(notes).delete_if { !note_sufficient?(it) }
  end

  def remove_contributors_without_value(contributors)
    Array(contributors).delete_if { !contributor_sufficient?(it) }
  end

  def remove_events_without_value(events)
    Array(events).delete_if { !event_sufficient?(it) }
  end

  def remove_languages_without_value(languages)
    Array(languages).delete_if { !language_sufficient?(it) }
  end

  # @param [Array<Hash>] dates an array of hashes that each represent a DescriptiveValue.
  def remove_dates_without_value(dates)
    Array(dates).delete_if { !descriptive_value_sufficient?(it) }
  end

  # Ignore DescriptiveValue that is just "type" or "source"
  def descriptive_value_sufficient?(descriptive_value)
    %i[value code uri identifier note valueAt structuredValue parallelValue groupedValue].any? do |key|
      descriptive_value[key].present?
    end
  end

  def note_sufficient?(note)
    %i[value valueAt structuredValue parallelValue groupedValue].any? do |key|
      note[key].present?
    end
  end

  def contributor_sufficient?(contributor)
    %i[identifier name valueAt].any? do |key|
      contributor[key].present?
    end
  end

  # Ignore Language that is just "type" or "source"
  def language_sufficient?(language)
    %i[value code uri note script valueAt structuredValue parallelValue groupedValue].any? do |key|
      language[key].present?
    end
  end

  # Ignore Event that is just "type"
  def event_sufficient?(event)
    %i[date contributor location identifier note structuredValue].any? do |key|
      event[key].present?
    end
  end
end
