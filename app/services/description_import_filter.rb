# frozen_string_literal: true

# This removes nodes from the generated cocina that we don't want to keep.
# Typically this is for things like a date has a type (e.g. "created"), but no value.
class DescriptionImportFilter
  # @param compacted_params [Hash]
  # @return [Cocina::Model::Description]
  # @raises Cocina::Models::ValidationError
  def self.filter(compacted_params)
    new.filter(compacted_params)
  end

  def filter(compacted_params)
    remove_contributors_without_value(compacted_params)
    remove_form_without_value(compacted_params)
    remove_language_without_value(compacted_params)
    remove_nested_attributes_without_value(compacted_params)

    Cocina::Models::Description.new(compacted_params)
  end

  private

  def remove_contributors_without_value(compacted_params_hash)
    return unless compacted_params_hash && compacted_params_hash[:contributor]

    compacted_params_hash[:contributor].delete_if do |contributor|
      contributor[:name].nil? && contributor[:identifier].blank? && contributor[:valueAt].blank?
    end
  end

  def remove_form_without_value(compacted_params_hash)
    compacted_params_hash[:form]&.delete_if { !descriptive_value_sufficient?(it) }
  end

  def remove_language_without_value(compacted_params_hash)
    return unless compacted_params_hash && compacted_params_hash[:language]

    compacted_params_hash[:language].delete_if do |language|
      !language_sufficient?(language)
    end
  end

  # Ignore Language that is just "type" or "source"
  def language_sufficient?(descriptive_value)
    %i[value code uri note script valueAt structuredValue parallelValue groupedValue].any? do |key|
      descriptive_value[key].present?
    end
  end

  # date is an array of DescriptiveValue.
  def remove_date_without_value(compacted_params_hash)
    return unless compacted_params_hash && compacted_params_hash[:date]

    compacted_params_hash[:date].delete_if { !descriptive_value_sufficient?(it) }
  end

  # Ignore DescriptiveValue that is just "type" or "source"
  def descriptive_value_sufficient?(descriptive_value)
    %i[value code uri identifier note valueAt structuredValue parallelValue groupedValue].any? do |key|
      descriptive_value[key].present?
    end
  end

  def remove_nested_attributes_without_value(compacted_params_hash)
    # event can have contributors and dates, geographic can have form, relatedResource can have form and/or contributor
    %i[relatedResource event geographic].each do |parent_property|
      next if compacted_params_hash[parent_property].blank?

      compacted_params_hash[parent_property].each do |parent_object|
        remove_contributors_without_value(parent_object) unless parent_property == :geographic
        remove_form_without_value(parent_object) unless parent_property == :event
        remove_date_without_value(parent_object) if parent_property == :event
      end
    end
  end
end
