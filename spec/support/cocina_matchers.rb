# frozen_string_literal: true

# Provides RSpec matchers for Cocina models
RSpec::Matchers.define :a_cocina_object_with_types do |expected|
  match do |actual|
    return false if expected[:without_order] && !match_no_orders?

    if expected[:content_type] && expected[:resource_types]
      match_cocina_type?(actual, expected) && match_contained_cocina_types?(actual, expected)
    elsif expected[:content_type] && expected[:viewing_direction]
      match_cocina_type?(actual, expected) && match_cocina_viewing_direction?(actual, expected)
    elsif expected[:content_type]
      match_cocina_type?(actual, expected)
    elsif expected[:resource_types]
      match_contained_cocina_types?(actual, expected)
    else
      raise ArgumentError, 'must provide content_type and/or resource_types keyword args'
    end
  end

  def match_no_orders?
    actual.structural.hasMemberOrders.blank?
  end

  def match_cocina_type?(actual, expected)
    actual.type == expected[:content_type]
  end

  def match_cocina_viewing_direction?(actual, expected)
    actual.structural.hasMemberOrders.map(&:viewingDirection).all? { |viewing_direction| viewing_direction == expected[:viewing_direction] }
  end

  def match_contained_cocina_types?(actual, expected)
    Array(actual.structural.contains).map(&:type).all? { |type| type.in?(expected[:resource_types]) }
  end
end

RSpec::Matchers.define :a_cocina_admin_policy_with_registration_collections do |expected|
  match do |actual|
    actual.type == Cocina::Models::Vocab.admin_policy &&
      expected.all? { |collection_id| collection_id.in?(actual.administrative.collectionsForRegistration) }
  end
end

# NOTE: each k/v pair in the hash passed to this matcher will need to be present in actual
RSpec::Matchers.define :a_cocina_object_with_access do |expected|
  match do |actual|
    expected.all? do |expected_key, expected_value|
      # NOTE: there's no better method on Hash that I could find for this.
      #        #include? and #member? only check keys, not k/v pairs
      actual.access.to_h.any? do |actual_key, actual_value|
        actual_key == expected_key && actual_value == expected_value
      end
    end
  end
end

# NOTE: each k/v pair in the hash passed to this matcher will need to be present in actual
RSpec::Matchers.define :a_cocina_object_with_identification do |expected|
  match do |actual|
    expected.all? do |expected_key, expected_value|
      # NOTE: there's no better method on Hash that I could find for this.
      #        #include? and #member? only check keys, not k/v pairs
      actual.identification.to_h.any? do |actual_key, actual_value|
        actual_key == expected_key && actual_value == expected_value
      end
    end
  end
end
