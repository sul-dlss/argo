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
  attr_reader :invalid_cocina_message

  def initialize(cocina_object:, without_metadata: false)
    @cocina_object_hash = if cocina_object.is_a?(Hash)
                            # This is what dor-services-client returns if invalid Cocina is requested
                            # TODO: Figure out how to get cocina_object[:error_message] in the right place
                            cocina_object[:cocina_object]
                          elsif without_metadata
                            Cocina::Models.without_metadata(cocina_object).to_h
                          else
                            cocina_object.to_h
                          end
    @invalid_cocina_message = cocina_object[:error_message] if cocina_object.is_a?(Hash)
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
end
