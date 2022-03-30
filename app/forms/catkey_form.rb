# frozen_string_literal: true

class CatkeyForm < ApplicationChangeSet
  property :catkey, virtual: true

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    self.catkey = Catkey.symphony_links(model).join(', ')
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    return unless changed?(:catkey)

    updated = model
    identification_props = updated.identification.new(catalogLinks: Catkey.serialize(model, catkey.split(/\s*,\s*/)))
    updated = updated.new(identification: identification_props)

    object_client.update(params: updated)
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end
end
