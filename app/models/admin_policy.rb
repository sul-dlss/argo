# frozen_string_literal: true

class AdminPolicy < ApplicationModel
  define_attribute_methods :id, :version, :label, :admin_policy_id,
                           :registration_workflows, :collections_for_registration, :access_template, :roles

  attribute :id
  attribute :version
  attribute :label
  attribute :admin_policy_id
  attribute :registration_workflows
  attribute :collections_for_registration
  attribute :access_template
  attribute :roles

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.id = model.externalIdentifier
    self.version = model.version
    self.label = model.label
    self.admin_policy_id = model.administrative.hasAdminPolicy
    self.registration_workflows = model.administrative.registrationWorkflow
    self.collections_for_registration = model.administrative.collectionsForRegistration
    self.access_template = AccessTemplate.new(model.administrative.accessTemplate)
    self.roles = model.administrative.roles
  end

  def save
    raise 'not implemented'
    # @model = AdminPolicyChangeSetPersister.update(model, self)
  end

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'AdminPolicy')
  end
end
