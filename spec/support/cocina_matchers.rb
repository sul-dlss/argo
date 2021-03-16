# frozen_string_literal: true

# Provides RSpec matchers for Cocina models
RSpec::Matchers.define :a_cocina_object_with_types do |expected|
  match do |actual|
    if expected[:content_type] && expected[:resource_types]
      match_cocina_type?(actual, expected) && match_contained_cocina_types?(actual, expected)
    elsif expected[:content_type]
      match_cocina_type?(actual, expected)
    elsif expected[:resource_types]
      match_contained_cocina_types?(actual, expected)
    else
      raise ArgumentError, 'must provide content_type and/or resource_types keyword args'
    end
  end

  def match_cocina_type?(actual, expected)
    actual.type == expected[:content_type]
  end

  def match_contained_cocina_types?(actual, expected)
    actual.structural.contains.map(&:type).all? { |type| type.in?(expected[:resource_types]) }
  end
end
