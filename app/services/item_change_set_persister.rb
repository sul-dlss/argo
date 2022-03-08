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
    object_client.update(params: updated_model)
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

  delegate :admin_policy_id, :barcode, :catkey, :source_id, :collection_ids,
           :embargo_release_date, :embargo_access,
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

  # NOTE: This must be called after updating the access
  def update_structural(updated)
    return updated unless changed?(:collection_ids) || object_permissions_changed?

    # updated = update_files(updated)
    updated_structural = if collection_ids
                           updated.structural.new(isMemberOf: collection_ids)
                         else
                           updated.structural.to_h.without(:isMemberOf) # clear collection membership
                         end
    updated.new(structural: updated_structural)
  end

  def access_changed?
    embargo_changed? || ACCESS_FIELDS.keys.any? { |field| changed?(field) }
  end

  # This is a subset of access_changed? that ignores copyright, license, use_statement, and embargo.
  def object_permissions_changed?
    %i[view_access download_access access_location controlled_digital_lending].any? { |field| changed?(field) }
  end

  def identification_changed?
    changed?(:source_id) || changed?(:catkey) || changed?(:barcode)
  end

  def embargo_changed?
    %i[embargo_release_date embargo_access].any? { |field| changed?(field) }
  end

  def updated_access(updated)
    return updated unless access_changed?

    props = updated_access_properties.merge(updated_embargo(updated.access))
    updated.new(access: updated.access.new(props))
  end

  def updated_access_properties
    {}.tap do |access_properties|
      ACCESS_FIELDS.filter { |field, _cocina_field| changed?(field) }.each do |field, cocina_field|
        val = public_send(field)
        access_properties[cocina_field] = val.is_a?(String) ? val.presence : val # allow boolean false
      end
    end
  end

  def updated_embargo(existing_access)
    @updated_embargo ||= begin
      embargo_class = existing_access.embargo || Cocina::Models::Embargo
      embargo_props.present? ? { embargo: embargo_class.new(embargo_props) } : {}
    end
  end

  def embargo_props
    @embargo_props ||= begin
      new_embargo_props = {}
      new_embargo_props[:releaseDate] = embargo_release_date if changed?(:embargo_release_date)

      new_embargo_props.merge!(embargo_rights) if changed?(:embargo_access)
      new_embargo_props
    end
  end

  def embargo_rights
    CocinaDroAccess.from_form_value(embargo_access).value_or(nil) if embargo_access.present?
  end

  def update_identification(updated)
    return updated unless identification_changed?

    identification_props = updated.identification&.to_h || {}
    identification_props[:sourceId] = source_id if changed?(:source_id)
    identification_props[:barcode] = barcode.presence if changed?(:barcode)
    identification_props[:catalogLinks] = Catkey.serialize(model, catkey) if changed?(:catkey)
    updated.new(identification: identification_props.presence)
  end
end
