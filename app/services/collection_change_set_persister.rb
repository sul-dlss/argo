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
    updated = updated_administrative(updated) if changed?(:admin_policy_id)
    object_client.update(params: updated)
  end

  private

  # The map between the change set fields and the Cocina field names
  ACCESS_FIELDS = {
    copyright: :copyright,
    license: :license,
    use_statement: :useAndReproductionStatement,
    view_access: :access
  }.freeze

  attr_reader :model, :change_set

  delegate :admin_policy_id, :catkey, *ACCESS_FIELDS.keys, :changed?, to: :change_set

  def access_changed?
    ACCESS_FIELDS.keys.any? { |field| changed?(field) }
  end

  def updated_access(updated)
    updated.new(access: updated.access.new(updated_access_properties))
  end

  def updated_access_properties
    {}.tap do |access_properties|
      ACCESS_FIELDS.each do |field, cocina_field|
        access_properties[cocina_field] = public_send(field).presence if changed?(field)
      end
    end
  end

  def update_identification(updated)
    identification_props = updated.identification&.to_h || {}
    identification_props[:catalogLinks] = Catkey.serialize(model, catkey) if changed?(:catkey)
    updated.new(identification: identification_props.compact.presence)
  end

  def updated_administrative(updated)
    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end
end
