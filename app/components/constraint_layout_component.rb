# frozen_string_literal: true

class ConstraintLayoutComponent < Blacklight::ConstraintLayoutComponent
  attr_reader :value, :label, :remove_path, :classes

  def remove_aria_label
    return I18n.t('blacklight.search.filters.remove.value', value:) if label.blank?

    I18n.t('blacklight.search.filters.remove.label_value', label:, value:)
  end
end
