# frozen_string_literal: true

class CatkeyForm < Reform::Form
  collection :catkeys, prepopulator: ->(*) { catkeys << CatkeyForm::Row.new(value: '', refresh: true) if catkeys.size.zero? },
                       populator: lambda { |collection:, index:, **|
                                    if item = collection[index] # rubocop:disable Lint/AssignmentInCondition
                                      item
                                    else
                                      collection.insert(index, CatkeyForm::Row.new)
                                    end
                                  } do
    property :value
    property :refresh # ActiveModel::Type::Boolean.new.cast('1')
    property :_destroy, virtual: true
  end

  validate :catkeys_acceptable

  ### classes that define a virtual catkey model object and data structure, used in form editing...persistence is in the cocina model
  class ModelProxy
    def initialize(id:, catkeys:)
      @id = id # the object ID
      @catkeys = catkeys # the array of catkey objects (defined in custom class below)
    end

    attr_reader :id, :catkeys

    def to_param
      @id
    end

    def persisted?
      true
    end
  end

  class Row
    attr_accessor :value, :refresh, :id

    def initialize(attrs = {})
      @id = attrs[:value]
      @value = attrs[:value]
      @refresh = attrs[:refresh]
    end

    def persisted?
      id.present?
    end

    # from https://github.com/rails/rails/blob/f95c0b7e96eb36bc3efc0c5beffbb9e84ea664e4/activerecord/lib/active_record/nested_attributes.rb#L382-L384
    def _destroy; end
  end
  ###

  def catkeys_acceptable
    # at most one catkey (not being deleted) can be set to refresh == true
    errors.add(:refresh, 'is only allowed for a single catkey.') if catkeys.count { |catkey| catkey.refresh == 'true' && catkey._destroy != '1' } > 1
    # must match the expected pattern
    errors.add(:catkey, 'must be in an allowed format') if catkeys.count { |catkey| catkey.value.match(/^\d+(:\d+)*$/).nil? }.positive?
  end

  def save(cocina_object)
    return false if catkeys.size.zero? # nothing submitted on the form

    # fetch the existing previous catkey values from the cocina object
    existing_previous_catkeys = Catkey.new(cocina_object).previous_links

    # these are all of the existing catkey values the user wants to remove (i.e. for which they clicked the trash icon)
    removed_catkeys = catkeys.filter_map { |catkey| catkey.value if catkey._destroy == '1' }

    # build an array of all previous catkeys (which includes the existing previous catkeys plus any newly removed ones)
    updated_previous_catkeys = (existing_previous_catkeys + removed_catkeys).map do |catkey_value|
      { catalog: Constants::PREVIOUS_CATKEY, catalogRecordId: catkey_value, refresh: false }
    end.uniq

    # build an array of submitted catkeys (i.e. for which they did NOT click the trash icon): could be unchanged, changed, or new)
    updated_catkeys = catkeys.filter_map do |catkey|
      { catalog: Constants::SYMPHONY, catalogRecordId: catkey.value, refresh: (catkey.refresh == 'true') } unless catkey._destroy == '1'
    end

    # now store everything in the cocina object
    updated_object = cocina_object
    identification_props = updated_object.identification.new(catalogLinks: updated_previous_catkeys + updated_catkeys)
    updated_object = updated_object.new(identification: identification_props)
    Repository.store(updated_object)
  end
end
