# frozen_string_literal: true

# Filters empty descriptive elements from Cocina object and return as a hash
#
# Why a hash?
#
# 1. If a Cocina object is returned, the empty descriptive elements will be present.
# 2. A hash is easier to work with (compare against, etc.) than a JSON string, and
#    it's super easy to coerce a hash into other data structures, so it gives us
#    flexibility.
class CocinaHashPresenter
  def initialize(cocina_object:, without_metadata: false)
    @cocina_object_hash = hash_from(cocina_object, without_metadata)
  end

  def render
    return cocina_object_hash unless cocina_object_hash[:description]

    cocina_object_hash.tap do |hash|
      hash[:description] = DeepCompactBlank.run(enumerable: hash[:description])
      # If other presentation tweaks are needed, they can live here.
    end
  end

  private

  attr_reader :cocina_object_hash

  def hash_from(cocina_object, without_metadata)
    return Cocina::Models.without_metadata(cocina_object).to_h if without_metadata

    cocina_object.to_h
  end
end
