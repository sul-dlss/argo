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
      .then { |updated| updated_structural_collections(updated) }
      .then { |updated| updated_access(updated) }

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

  delegate :admin_policy_id, :barcode, :catkeys, :refresh, :source_id, :collection_ids,
    *ACCESS_FIELDS.keys, :rights_changed?,
    :changed?, to: :change_set

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def updated_administrative(updated)
    return updated unless changed?(:admin_policy_id)

    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end

  def updated_structural_collections(updated)
    return updated unless changed?(:collection_ids)

    updated_structural = if collection_ids
      updated.structural.new(isMemberOf: collection_ids)
    else
      updated.structural.to_h.without(:isMemberOf) # clear collection membership
    end
    updated.new(structural: updated_structural)
  end

  ### Access and structural have to be updated simultaneously or it may trigger
  ### the validation about the file being published when access is dark.
  # @param [Cocina::Models::Dro] updated the DRO metadata to modify
  def updated_access(updated)
    updated.new(
      structural: structural_with_updated_file_access(updated),
      access: updated_object_access(updated)
    )
  end

  # If the rights on the object were changed, then we copy the new rights to the file level
  # @param [Cocina::Models::Dro] updated the DRO metadata to modify
  # @return [Cocina::Models::DROStructural] the new structural modified to have appropriate file access.
  def structural_with_updated_file_access(updated)
    return updated.structural unless rights_changed?

    # Convert to hash so we can mutate it
    structure_hash = updated.structural.to_h
    Array(structure_hash[:contains]).each do |fileset|
      fileset[:structural][:contains].each do |file|
        case view_access
        when "dark"
          # Ensure files attached to dark objects are neither published nor shelved
          file[:access].merge!(view: "dark", download: "none", controlledDigitalLending: false, location: nil)
          file[:administrative][:publish] = false
          file[:administrative].merge!(shelve: false)
        when "citation-only"
          file[:access].merge!(view: "dark", download: "none", controlledDigitalLending: false, location: nil)
        else
          file[:access].merge!(view: view_access,
            download: download_access,
            controlledDigitalLending: controlled_digital_lending,
            location: access_location)
        end
      end
    end
    Cocina::Models::DROStructural.new(structure_hash)
  end

  def access_changed?
    ACCESS_FIELDS.keys.any? { |field| changed?(field) }
  end

  def identification_changed?
    changed?(:source_id) || changed?(:catkeys) || changed?(:barcode) || changed?(:refresh)
  end

  def updated_object_access(updated)
    access_changed? ? updated.access.new(updated_access_properties) : updated.access
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
    identification_props[:catalogLinks] = Catkey.serialize(model, catkeys, refresh:) if changed?(:catkeys) || changed?(:refresh)
    # TODO: when cocina-models 0.87.1 is released, replace this block with:
    # identification_props[:barcode] = barcode.presence if changed?(:barcode)
    # and unskip the two related skipped specs
    if changed?(:barcode)
      if barcode.present?
        identification_props[:barcode] = barcode
      else
        identification_props.delete(:barcode)
      end
    end

    updated.new(identification: identification_props.presence)
  end
end
