# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catkey, virtual: true
  property :collection_ids, virtual: true
  property :copyright, virtual: true
  property :embargo_release_date, virtual: true
  property :embargo_access, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true

  validates :embargo_access, inclusion: {
    in: Constants::REGISTRATION_RIGHTS_OPTIONS.map(&:second),
    allow_blank: true
  }

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Item')
  end

  def id
    model.externalIdentifier
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    if model.identification
      self.catkey = Catkey.deserialize(model)
      self.barcode = model.identification.barcode
    end

    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license

    setup_embargo_properties! if model.access.embargo
  end

  def setup_embargo_properties!
    embargo = model.access.embargo
    self.embargo_release_date = embargo.releaseDate.to_date.to_s(:default)
    self.embargo_access = if embargo.access == 'location-based'
                            "loc:#{embargo.readLocation}"
                          elsif embargo.download == 'none' && embargo.access.in?(%w[stanford world])
                            "#{embargo.access}-nd"
                          else
                            embargo.access
                          end
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    ItemChangeSetPersister.update(model, self)
  end
end
