# frozen_string_literal: true

# This presenter is for content based on cocina structural content
class StructuralPresenter
  def initialize(structural)
    @structural = structural
  end

  attr_reader :structural

  def label
    return 'Constituent' if virtual_object?

    'Resource'
  end

  # Determine if the upload/download CSV links should be enabled
  # Returns true if there are content items and it is not a virtual object
  def enable_csv?
    return false if virtual_object? || number_of_content_items.nil?

    number_of_content_items.positive?
  end

  def number_of_content_items
    return constituents.size if virtual_object?

    structural&.contains&.size
  end

  def virtual_object?
    constituents.present?
  end

  def constituents
    return nil unless structural
    return nil if structural.hasMemberOrders.blank?

    @constituents ||= structural.hasMemberOrders.first&.members
  end
end
