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
    updated = update_identification(updated) if source_id_changed? || catkey_changed?
    updated = updated_administrative(updated) if admin_policy_id_changed?
    updated = updated_access(updated) if access_changed?
    object_client.update(params: updated)
  end

  private

  attr_reader :model, :change_set

  delegate :collection_ids_changed?, :source_id_changed?, :catkey_changed?, :admin_policy_id_changed?,
           :collection_ids, :source_id, :catkey, :admin_policy_id, :license, :license_changed?,
           :copyright_statement, :copyright_statement_changed?, :use_statement, :use_statement_changed?,
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
    copyright_statement_changed? || license_changed? || use_statement_changed?
  end

  def updated_access(updated)
    access_properties = {
      copyright: copyright_statement_changed? ? copyright_statement : updated.access.copyright,
      license: license_changed? ? license : updated.access.license,
      useAndReproductionStatement: use_statement_changed? ? use_statement : updated.access.useAndReproductionStatement
    }.compact

    updated.new(access: updated.access.new(access_properties))
  end

  def update_identification(updated)
    updated_identification = updated.identification
    updated_identification = updated_identification.new(sourceId: source_id) if source_id_changed?
    if catkey_changed?
      catalog_links = []
      catalog_links << { catalog: 'symphony', catalogRecordId: catkey } if catkey
      updated_identification = updated_identification.new(catalogLinks: catalog_links)
    end

    updated.new(identification: updated_identification)
  end
end
