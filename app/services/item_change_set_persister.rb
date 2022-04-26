# frozen_string_literal: true

# Writes updates Cocina Models
class ItemChangeSetPersister
  # @param [Cocina::Models::DRO] model the orignal state of the model
  # @param [ItemChangeSet] change_set the values to update.
  # @return [Cocina::Models::DRO] the model with updates applied
  def self.update(model, change_set)
    new(model, change_set).update
  end

  def initialize(model, change_set)
    @model = model
    @change_set = change_set
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  def update
    updated_model = update_identification(model)
                    .then { |updated| updated_administrative(updated) }
                    .then { |updated| updated_access(updated) }
                    .then { |updated| update_structural(updated) }
    Repository.store(updated_model)
  end

  private

  # The map between the change set fields and the Cocina field names
  ACCESS_FIELDS = {
    copyright: :copyright,
    license: :license,
    use_statement: :useAndReproductionStatement,
    view_access: :view,
    download_access: :download,
    access_location: :location,
    controlled_digital_lending: :controlledDigitalLending
  }.freeze

  attr_reader :model, :change_set

  delegate :admin_policy_id, :barcode, :catkeys, :source_id, :collection_ids,
           *ACCESS_FIELDS.keys,
           :changed?, to: :change_set

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def updated_administrative(updated)
    return updated unless changed?(:admin_policy_id)

    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end

  def update_structural(updated)
    return updated unless changed?(:collection_ids)

    updated_structural = if collection_ids
                           updated.structural.new(isMemberOf: collection_ids)
                         else
                           updated.structural.to_h.without(:isMemberOf) # clear collection membership
                         end
    updated.new(structural: updated_structural)
  end

  def access_changed?
    ACCESS_FIELDS.keys.any? { |field| changed?(field) }
  end

  def identification_changed?
    changed?(:source_id) || changed?(:catkeys) || changed?(:barcode)
  end

  def updated_access(updated)
    return updated unless access_changed?

    updated.new(access: updated.access.new(updated_access_properties))
  end

  def updated_access_properties
    {}.tap do |access_properties|
      ACCESS_FIELDS.filter { |field, _cocina_field| changed?(field) }.each do |field, cocina_field|
        val = public_send(field)
        access_properties[cocina_field] = val.is_a?(String) ? val.presence : val # allow boolean false
      end
    end
  end

  def update_identification(updated)
    return updated unless identification_changed?

    identification_props = updated.identification.to_h
    identification_props[:sourceId] = source_id if changed?(:source_id)
    identification_props[:barcode] = barcode.presence if changed?(:barcode)
    identification_props[:catalogLinks] = Catkey.serialize(model, catkeys) if changed?(:catkeys)
    updated.new(identification: identification_props.presence)
  end
end
