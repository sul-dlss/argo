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
    contributor: :contributor_sufficient?,
    date: :descriptive_value_sufficient?,
    digitalLocation: :descriptive_value_sufficient?,
    event: :event_sufficient?,
    form: :descriptive_value_sufficient?,
    identifier: :descriptive_value_sufficient?,
    language: :language_sufficient?,
    name: :descriptive_value_sufficient?,
    note: :note_sufficient?,
    structuredValue: :descriptive_value_sufficient?,
    subject: :descriptive_value_sufficient?
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
      next if model.attribute_names.exclude?(attribute)
      next if (values = compacted_params[attribute]).blank?

      Array(values).delete_if { |value| !send(method, value) }
    end

    compacted_params.compact_blank!
  end

  private

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
