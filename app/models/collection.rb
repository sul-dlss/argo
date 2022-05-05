# frozen_string_literal: true

class Collection < ApplicationModel
  define_attribute_methods :id, :version, :admin_policy_id, :catkeys, :copyright,
                           :license, :source_id, :use_statement, :view_access

  attribute :id
  attribute :version
  attribute :admin_policy_id
  attribute :catkeys
  attribute :copyright
  attribute :license
  attribute :source_id
  attribute :use_statement
  attribute :view_access

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!
    self.id = model.externalIdentifier
    self.version = model.version
    self.admin_policy_id = model.administrative.hasAdminPolicy

    self.catkeys = Catkey.symphony_links(model) if model.identification
    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license
    self.source_id = model.identification&.sourceId

    self.view_access = model.access.view
  end

  def save
    @model = CollectionPersister.update(model, self)
  end

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Collection')
  end
end
