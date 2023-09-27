# frozen_string_literal: true

require "reform/form/coercion"

class CatalogRecordIdForm < Reform::Form
  ### classes that define a virtual catalog record ID model object and data structure, used in form editing...persistence is in the cocina model
  class Row
    attr_accessor :value, :refresh, :catalog, :_destroy

    def initialize(attrs = {})
      @value = attrs[:value]
      @refresh = attrs[:refresh]
      @catalog = attrs[:catalog] # TODO: Remove when done with Folio migration
    end

    def persisted?
      false
    end
  end
  ###

  feature Reform::Form::Coercion

  collection :catalog_record_ids, populate_if_empty: Row, save: false, virtual: true,
    prepopulator: ->(*) { catalog_record_ids << CatalogRecordIdForm::Row.new(value: "", refresh: true) if catalog_record_ids.size.zero? } do
    property :value
    property :refresh, type: Dry::Types["params.nil"] | Dry::Types["params.bool"]
    property :_destroy
  end

  # TODO: Remove when done with Folio migration
  collection :other_catalog_record_ids, save: false, virtual: true do
    property :value
    property :catalog
    property :refresh, type: Dry::Types["params.nil"] | Dry::Types["params.bool"]
    property :_destroy
  end

  validate :single_catalog_record_id_refresh
  validate :unique_catalog_record_id_value
  validate :valid_catalog_record_id_value

  # needed because our model in this form is a cocina object and not an active record model, and Reform calls `persisted?`
  def persisted?
    false
  end

  def setup_properties!(_options)
    object_catalog_record_ids = model.identification.catalogLinks.filter_map { |catalog_link| catalog_link if catalog_link.catalog == CatalogRecordId.type }

    self.catalog_record_ids = object_catalog_record_ids.map { |catalog_record_id| CatalogRecordIdForm::Row.new(value: catalog_record_id.catalogRecordId, refresh: catalog_record_id.refresh) }

    other_object_catalog_record_ids = model.identification.catalogLinks.filter_map { |catalog_link| catalog_link if catalog_link.catalog.exclude?(CatalogRecordId.type) }

    self.other_catalog_record_ids = other_object_catalog_record_ids.map { |catalog_record_id| CatalogRecordIdForm::Row.new(value: catalog_record_id.catalogRecordId, refresh: catalog_record_id.refresh, catalog: catalog_record_id.catalog) }
  end

  def unique_catalog_record_id_value
    # each catalog record ID must be unique
    catalog_record_id_values = catalog_record_ids.map(&:value)
    errors.add(:catalog_record_id, "must be unique") if catalog_record_id_values.size != catalog_record_id_values.uniq.size
  end

  def valid_catalog_record_id_value
    # must match the expected pattern
    errors.add(:catalog_record_id, "must be in an allowed format") unless CatalogRecordId.valid?(catalog_record_ids.map(&:value))
  end

  def single_catalog_record_id_refresh
    # at most one catalog record ID per catalog (e.g., Folio) can be set to refresh == true
    errors.add(:refresh, "is only allowed for a single catalog record ID.") if catalog_record_ids.count { |id| id.refresh && id._destroy != "1" } > 1
  end

  # this is overriding Reforms save method, since we are persisting catalog record IDs in cocina only
  def save_model
    refresh_catalog_record_id_from_form = catalog_record_ids.find { |id| id.refresh && id._destroy != "1" }&.value
    non_refresh_catalog_record_ids_from_form = catalog_record_ids.filter_map { |id| id.value if id.refresh != true && id._destroy != "1" }
    catalog_record_ids_from_form = [refresh_catalog_record_id_from_form].compact + non_refresh_catalog_record_ids_from_form

    new_catalog_links = CatalogRecordId.serialize(model, catalog_record_ids_from_form, refresh: refresh_catalog_record_id_from_form.present?)

    # now store everything in the cocina object
    updated_object = model
    identification_props = updated_object.identification.new(catalogLinks: new_catalog_links)
    updated_object = updated_object.new(identification: identification_props)
    Repository.store(updated_object)
  end
end
