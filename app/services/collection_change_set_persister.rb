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
    updated = updated_access(updated) if access_changed?
    object_client.update(params: updated)
  end

  private

  attr_reader :model, :change_set

  delegate :license, :copyright_statement, :use_statement, :changed?, to: :change_set

  def access_changed?
    changed?(:copyright_statement) || changed?(:license) || changed?(:use_statement)
  end

  def updated_access(updated)
    updated.new(
      access: updated.access.new(
        copyright: changed?(:copyright_statement) ? copyright_statement : updated.access.copyright,
        license: changed?(:license) ? license : updated.access.license,
        useAndReproductionStatement: changed?(:use_statement) ? use_statement : updated.access.useAndReproductionStatement
      )
    )
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end
end
