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
    form: :remove_form_without_value,
    identifier: :remove_identifiers_without_value,
    language: :remove_language_without_value,
    date: :remove_date_without_value,
    subject: :remove_subject_without_value
  }.freeze

  MODELS_WITH_NESTED_ATTRIBUTES = {
    relatedResource: Cocina::Models::RelatedResource,
    event: Cocina::Models::Event,
    geographic: Cocina::Models::DescriptiveGeographicMetadata,
    adminMetadata: Cocina::Models::DescriptiveAdminMetadata
  }.freeze

  # recursive, breadth first search for incomplete nodes
  def filter(compacted_params, model: Cocina::Models::Description)
    ATTRIBUTES_TO_FILTER.each do |attribute, method|
      send(method, compacted_params[attribute]) if model.attribute_names.include?(attribute)
    end

    MODELS_WITH_NESTED_ATTRIBUTES.each do |attribute, model|
      case compacted_params[attribute]
      when Hash
        filter(compacted_params[attribute], model:)
      when Array
        compacted_params[attribute].each { |attributes| filter(attributes, model:) }
      end
    end

    compacted_params
  end

  private

  def remove_contributors_without_value(contributors)
    Array(contributors).delete_if do |contributor|
      contributor[:name].nil? && contributor[:identifier].blank? && contributor[:valueAt].blank?
    end
  end

  def remove_identifiers_without_value(identifiers)
    Array(identifiers).delete_if { !descriptive_value_sufficient?(it) }
  end

  def remove_form_without_value(forms)
    Array(forms).delete_if { !descriptive_value_sufficient?(it) }
  end

  def remove_subject_without_value(subjects)
    Array(subjects).delete_if { !descriptive_value_sufficient?(it) }
  end

  def remove_language_without_value(languages)
    Array(languages).delete_if { !language_sufficient?(it) }
  end

  # Ignore Language that is just "type" or "source"
  def language_sufficient?(descriptive_value)
    %i[value code uri note script valueAt structuredValue parallelValue groupedValue].any? do |key|
      descriptive_value[key].present?
    end
  end

  # @param [Array<Hash>] dates an array of hashes that each represent a DescriptiveValue.
  def remove_date_without_value(dates)
    Array(dates).delete_if { !descriptive_value_sufficient?(it) }
  end

  # Ignore DescriptiveValue that is just "type" or "source"
  def descriptive_value_sufficient?(descriptive_value)
    %i[value code uri identifier note valueAt structuredValue parallelValue groupedValue].any? do |key|
      descriptive_value[key].present?
    end
  end
end
