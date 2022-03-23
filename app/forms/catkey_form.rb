# frozen_string_literal: true

class CatkeyForm < ApplicationChangeSet
  property :catkey, virtual: true

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    self.catkey = model.catkeys.join(', ')
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def sync
    model.catkeys = catkey.split(/\s*,\s*/) if changed?(:catkey)
  end
end
