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

  SUFFICIENT_DESCRIPTIVE_VALUE_KEYS = %i[value code uri identifier note valueAt structuredValue parallelValue groupedValue].freeze
  ATTRIBUTES_TO_FILTER = {
    contributor: %i[identifier name valueAt],
    date: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    digitalLocation: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    event: %i[date contributor location identifier note structuredValue],
    form: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    identifier: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    language: %i[value code uri note script valueAt structuredValue parallelValue groupedValue],
    name: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    note: %i[value valueAt structuredValue parallelValue groupedValue],
    structuredValue: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS,
    subject: SUFFICIENT_DESCRIPTIVE_VALUE_KEYS
  }.freeze

  MODELS_WITH_NESTED_ATTRIBUTES = %i[
    access adminMetadata contributor date event form geographic name relatedResource structuredValue subject title
  ].freeze

  # Recursive, depth-first search for insufficient nodes
  def filter(compacted_params) # rubocop:disable Metrics/CyclomaticComplexity
    MODELS_WITH_NESTED_ATTRIBUTES.each do |attribute|
      case compacted_params[attribute]
      when Hash
        filter(compacted_params[attribute])
      when Array
        compacted_params[attribute].each { |attributes| filter(attributes) }
      end
    end

    ATTRIBUTES_TO_FILTER.each do |attribute, sufficient_values|
      next if (values = compacted_params[attribute]).blank?

      Array(values).delete_if do |value|
        sufficient_values.none? { |key| value[key].present? }
      end
    end

    compacted_params.compact_blank!
  end
end
