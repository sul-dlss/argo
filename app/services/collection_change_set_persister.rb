# frozen_string_literal: true

# Writes updates to Cocina collections
class CollectionChangeSetPersister
  # @param [Cocina::Models::Collection] model the orignal state of the collection
  # @param [CollectionChangeSet] change_set the values to update.
  # @return [Cocina::Models::Collection] the model with updates applied
  def self.update(model, change_set)
    new(model, change_set).update
  end

  def initialize(model, change_set)
    @model = model
    @change_set = change_set
  end

  def update
    updated = model
    updated = update_identification(updated) if changed?(:source_id) || changed?(:catkey)
    updated = updated_access(updated) if access_changed?
    updated = updated_administrative(updated) if administrative_changed?
    object_client.update(params: updated)
  end

  private

  attr_reader :model, :change_set

  delegate :admin_policy_id, :project, :license, :copyright, :use_statement, :catkey, :changed?, to: :change_set

  def access_changed?
    changed?(:copyright) || changed?(:license) || changed?(:use_statement)
  end

  def administrative_changed?
    changed?(:admin_policy_id) || changed?(:project)
  end

  def updated_access(updated)
    access_properties = {
      copyright: changed?(:copyright) ? copyright : updated.access.copyright,
      license: changed?(:license) ? license : updated.access.license,
      useAndReproductionStatement: changed?(:use_statement) ? use_statement : updated.access.useAndReproductionStatement
    }.compact

    updated.new(access: updated.access.new(access_properties))
  end

  def update_identification(updated)
    identification_props = updated.identification&.to_h || {}
    identification_props[:catalogLinks] = Catkey.serialize(model, catkey) if changed?(:catkey)
    updated.new(identification: identification_props.compact.presence)
  end

  def updated_administrative(updated)
    properties = {}
    properties[:hasAdminPolicy] = admin_policy_id if changed?(:admin_policy_id)
    properties[:partOfProject] = project if changed?(:project)

    updated_administrative = updated.administrative.new(properties)
    updated.new(administrative: updated_administrative)
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end
end
