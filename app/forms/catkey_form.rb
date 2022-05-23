# frozen_string_literal: true

require 'reform/form/coercion'

class CatkeyForm < Reform::Form
  ### classes that define a virtual catkey model object and data structure, used in form editing...persistence is in the cocina model
  class Row
    attr_accessor :value, :refresh, :_destroy

    def initialize(attrs = {})
      @value = attrs[:value]
      @refresh = attrs[:refresh]
    end

    def persisted?
      false
    end
  end
  ###

  feature Reform::Form::Coercion

  collection :catkeys, populate_if_empty: Row, save: false, virtual: true,
                       prepopulator: ->(*) { catkeys << CatkeyForm::Row.new(value: '', refresh: true) if catkeys.size.zero? } do
    property :value
    property :refresh, type: Dry::Types['params.nil'] | Dry::Types['params.bool']
    property :_destroy
  end

  validate :catkeys_acceptable

  # needed because our model in this form is a cocina object and not an active record model, and Reform calls `persisted?`
  def persisted?
    false
  end

  def setup_properties!(_options)
    object_catkeys = model.identification.catalogLinks.filter_map { |catalog_link| catalog_link if catalog_link.catalog == Constants::SYMPHONY }

    self.catkeys = object_catkeys.map { |catkey| CatkeyForm::Row.new(value: catkey.catalogRecordId, refresh: catkey.refresh) }
  end

  def catkeys_acceptable
    # at most one catkey can be set to refresh == true
    errors.add(:refresh, 'is only allowed for a single catkey.') if catkeys.count { |catkey| catkey.refresh && catkey._destroy != '1' } > 1
    # must match the expected pattern
    errors.add(:catkey, 'must be in an allowed format') if catkeys.count { |catkey| catkey.value.match(/^\d+(:\d+)*$/).nil? }.positive?
  end

  # this is overriding Reforms save method, since we are persisting catkeys in cocina only
  def save_model
    # fetch the existing previous catkey values from the cocina object
    existing_previous_catkeys = Catkey.new(model).previous_links

    # these are all of the existing catkey values the user wants to remove (i.e. for which they clicked the trash icon)
    removed_catkeys = catkeys.filter_map { |catkey| catkey.value if catkey._destroy == '1' }

    # build an array of all previous catkeys (which includes the existing previous catkeys plus any newly removed ones)
    updated_previous_catkeys = (existing_previous_catkeys + removed_catkeys).map do |catkey_value|
      { catalog: Constants::PREVIOUS_CATKEY, catalogRecordId: catkey_value, refresh: false }
    end.uniq

    updated_catkeys = catkeys.filter_map do |catkey|
      { catalog: Constants::SYMPHONY, catalogRecordId: catkey.value, refresh: catkey.refresh } unless catkey._destroy == '1'
    end

    # now store everything in the cocina object
    updated_object = model
    identification_props = updated_object.identification.new(catalogLinks: updated_previous_catkeys + updated_catkeys)
    updated_object = updated_object.new(identification: identification_props)
    Repository.store(updated_object)
  end
end
