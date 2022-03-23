# frozen_string_literal: true

# Writes updates to Cocina collections
class CollectionPersister
  # @param [Cocina::Models::Collection] model the orignal state of the collection
  # @param [Collection] change_set the values to update.
  # @return [Cocina::Models::Collection] the model with updates applied
  def self.update(model, change_set)
    new(model, change_set).update
  end

  def initialize(model, change_set)
    @model = model
    @change_set = change_set
  end

  def update
    updated_model = update_identification(model)
                    .then { |updated| updated_access(updated) }
                    .then { |updated| updated_administrative(updated) }

    Repository.store(updated_model)
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

  delegate :admin_policy_id, :catkeys, *ACCESS_FIELDS.keys,
           :source_id_changed?, :catkeys_changed?, :admin_policy_id_changed?,
           :copyright_changed?, :license_changed?, :use_statement_changed?,
           :view_access_changed?, to: :change_set

  def access_changed?
    ACCESS_FIELDS.keys.any? { |field| public_send("#{field}_changed?") }
  end

  def updated_access(updated)
    return updated unless access_changed?

    updated.new(access: updated.access.new(updated_access_properties))
  end

  def updated_access_properties
    {}.tap do |access_properties|
      ACCESS_FIELDS.each do |field, cocina_field|
        access_properties[cocina_field] = public_send(field).presence if public_send("#{field}_changed?")
      end
    end
  end

  def update_identification(updated)
    return updated unless source_id_changed? || catkeys_changed?

    identification_props = updated.identification&.to_h || {}
    identification_props[:catalogLinks] = Catkey.serialize(model, catkeys) if catkeys_changed?
    updated.new(identification: identification_props.compact.presence)
  end

  def updated_administrative(updated)
    return updated unless admin_policy_id_changed?

    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end
end
