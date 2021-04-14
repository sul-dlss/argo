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

  def update
    updated = model
    updated = update_structural(updated) if collection_ids_changed?
    updated = update_identification(updated) if source_id_changed? || catkey_changed? || barcode_changed?
    updated = updated_administrative(updated) if admin_policy_id_changed?
    updated = updated_access(updated) if access_changed?
    object_client.update(params: updated)
  end

  private

  attr_reader :model, :change_set

  delegate :admin_policy_id, :admin_policy_id_changed?,
           :barcode, :barcode_changed?,
           :catkey, :catkey_changed?,
           :collection_ids, :collection_ids_changed?,
           :copyright_statement, :copyright_statement_changed?,
           :embargo_release_date, :embargo_release_date_changed?,
           :license, :license_changed?,
           :source_id, :source_id_changed?,
           :use_statement, :use_statement_changed?,
           to: :change_set

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def updated_administrative(updated)
    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end

  def update_structural(updated)
    updated_structural = if collection_ids
                           updated.structural.new(isMemberOf: collection_ids)
                         else
                           updated.structural.to_h.without(:isMemberOf) # clear collection membership
                         end
    updated.new(structural: updated_structural)
  end

  def access_changed?
    copyright_statement_changed? || license_changed? || use_statement_changed? || embargo_release_date_changed?
  end

  def updated_access(updated)
    access_properties = {
      copyright: copyright_statement_changed? ? copyright_statement : updated.access.copyright,
      license: license_changed? ? license : updated.access.license,
      useAndReproductionStatement: use_statement_changed? ? use_statement : updated.access.useAndReproductionStatement
    }.compact

    access_properties[:embargo] = updated.access.embargo.new(releaseDate: embargo_release_date) if embargo_release_date_changed?

    updated.new(access: updated.access.new(access_properties))
  end

  def update_identification(updated)
    identification_props = updated.identification&.to_h || {}
    identification_props[:sourceId] = source_id if source_id_changed?
    identification_props[:barcode] = barcode if barcode_changed?
    if catkey_changed?
      identification_props[:catalogLinks] = catkey ? [{ catalog: 'symphony', catalogRecordId: catkey }] : nil
    end
    updated.new(identification: identification_props.compact.presence)
  end
end
