# frozen_string_literal: true

class AccessTemplate < ApplicationModel
  define_attribute_methods :license, :copyright, :use_statement, :view, :download

  attribute :license
  attribute :copyright
  attribute :use_statement
  attribute :view
  attribute :download

  def initialize(cocina_model = Cocina::Models::AdminPolicyAccessTemplate.new)
    super
  end

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.license = model.license
    self.copyright = model.copyright
    self.use_statement = model.useAndReproductionStatement
    self.view = model.view
    self.download = model.download
  end
end
