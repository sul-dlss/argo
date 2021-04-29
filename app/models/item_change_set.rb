# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  property :admin_policy_id, virtual: true
  property :catkey, virtual: true
  property :collection_ids, virtual: true
  property :copyright_statement, virtual: true
  property :embargo_release_date, virtual: true
  property :embargo_access, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true

  validates :embargo_access, inclusion: {
    in: Constants::REGISTRATION_RIGHTS_OPTIONS.map(&:second)
  }

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Item')
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    return unless model.identification

    self.catkey = model.identification.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
    self.barcode = model.identification.barcode
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

  def save_model
    ItemChangeSetPersister.update(model, self)
  end
end
