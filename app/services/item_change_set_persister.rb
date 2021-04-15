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
    updated = update_structural(updated) if changed?(:collection_ids)
    updated = update_identification(updated) if changed?(:source_id) || changed?(:catkey) || changed?(:barcode)
    updated = updated_administrative(updated) if changed?(:admin_policy_id)
    updated = updated_access(updated) if access_changed?
    object_client.update(params: updated)
  end

  private

  attr_reader :model, :change_set

  delegate :admin_policy_id, :barcode, :catkey, :collection_ids,
           :copyright_statement, :embargo_release_date, :embargo_access, :license, :source_id,
           :use_statement, :changed?, to: :change_set

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
    changed?(:copyright_statement) ||
      changed?(:license) ||
      changed?(:use_statement) ||
      changed?(:embargo_release_date) ||
      changed?(:embargo_access)
  end

  def updated_access(updated)
    access_properties = {
      copyright: changed?(:copyright_statement) ? copyright_statement : updated.access.copyright,
      license: changed?(:license) ? license : updated.access.license,
      useAndReproductionStatement: changed?(:use_statement) ? use_statement : updated.access.useAndReproductionStatement
    }.compact

    embargo_clazz = updated.access.embargo || Cocina::Models::Embargo
    access_properties[:embargo] = embargo_clazz.new(embargo_props) if embargo_props.present?

    updated.new(access: updated.access.new(access_properties))
  end

  def embargo_props
    @embargo_props ||= begin
      new_embargo_props = {}
      new_embargo_props[:releaseDate] = embargo_release_date if changed?(:embargo_release_date)
      new_embargo_props.merge!(embargo_access) if changed?(:embargo_access)
      new_embargo_props
    end
  end

  def update_identification(updated)
    identification_props = updated.identification&.to_h || {}
    identification_props[:sourceId] = source_id if changed?(:source_id)
    identification_props[:barcode] = barcode if changed?(:barcode)
    if changed?(:catkey)
      identification_props[:catalogLinks] = catkey ? [{ catalog: 'symphony', catalogRecordId: catkey }] : nil
    end
    updated.new(identification: identification_props.compact.presence)
  end
end
