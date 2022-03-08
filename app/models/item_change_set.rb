# frozen_string_literal: true

require 'reform/form/coercion'

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet # rubocop:disable Metrics/ClassLength
  feature Coercion # Casts properties to a specific type
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
  property :view_access, virtual: true
  property :download_access, virtual: true
  property :access_location, virtual: true
  property :controlled_digital_lending, virtual: true, type: Dry::Types['params.nil'] | Dry::Types['params.bool']

  validates :source_id, presence: true, if: -> { changed?(:source_id) }
  validates :embargo_access, inclusion: {
    in: Constants::REGISTRATION_RIGHTS_OPTIONS.map(&:second),
    allow_blank: true
  }

  validates :view_access, inclusion: {
    in: %w[world stanford location-based citation-only dark],
    allow_blank: true
  }

  validates :download_access, inclusion: {
    in: %w[world stanford location-based none],
    allow_blank: true
  }

  validates :access_location, inclusion: {
    in: %w[spec music ars art hoover m&m],
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
    self.view_access = model.access.view
    self.download_access = model.access.download
    self.access_location = model.access.location
    self.controlled_digital_lending = model.access.controlledDigitalLending

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

  # @param structural [Cocina::Models::DRO] the DRO metadata to modify
  # @return [Cocina::Models::DRO] a copy of the the Cocina model, with the new structural overlaid
  def update_files(updated)
    # Convert to hash so we can mutate it
    structure_hash = updated.structural.to_h
    Array(structure_hash[:contains]).each do |fileset|
      fileset[:structural][:contains].each do |file|
        case view_access
        when 'dark'
          # Ensure files attached to dark objects are neither published nor shelved
          file[:access].merge!(view: 'dark', download: 'none', controlledDigitalLending: false, location: nil)
          file[:administrative].merge!(publish: false)
          file[:administrative].merge!(shelve: false)
        when 'citation-only'
          file[:access].merge!(view: 'dark', download: 'none', controlledDigitalLending: false, location: nil)
        else
          file[:access].merge!(view: view_access,
                               download: download_access,
                               controlledDigitalLending: controlled_digital_lending,
                               location: access_location)
        end
      end
    end
    updated.new(structural: structure_hash)
  end

  def sync
    super
    self.download_access = 'none' if clear_download? # This must be before clearing location
    self.access_location = nil if clear_location?
  end

  def clear_download?
    %w[dark citation-only].include?(view_access)
  end

  def clear_location?
    (changed?(:view_access) || changed?(:download_access)) && view_access != 'location-based' && download_access != 'location-based'
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    updated = model
    updated = update_files(updated) if rights_changed? # This would ideally live in #sync, but reform doesn't support immutable models.
    ItemChangeSetPersister.update(updated, self)
  end

  def rights_changed?
    changed?(:view_access) || changed?(:download_access) || changed?(:location) || changed?(:controlled_digital_lending)
  end
end
