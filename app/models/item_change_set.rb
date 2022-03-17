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

  validates :source_id, presence: true, if: -> { changed?(:source_id) }
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
      self.source_id = model.identification.sourceId
    end

    self.copyright = model.access.copyright
    self.use_statement = model.access.useAndReproductionStatement
    self.license = model.access.license

    setup_embargo_properties! if model.access.embargo
  end

  def setup_embargo_properties!
    embargo = model.access.embargo
    self.embargo_release_date = embargo.releaseDate.to_date.to_fs(:default)
    self.embargo_access = if embargo.view == 'location-based'
                            "loc:#{embargo.location}"
                          elsif embargo.download == 'none' && embargo.view.in?(%w[stanford world])
                            "#{embargo.view}-nd"
                          else
                            embargo.view
                          end
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    ItemChangeSetPersister.update(model, self)
  end
end
