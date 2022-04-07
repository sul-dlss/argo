# frozen_string_literal: true

require 'reform/form/coercion'

# Represents a set of changes to an item.
class ItemChangeSet < ApplicationChangeSet
  feature Coercion # Casts properties to a specific type

  property :admin_policy_id
  property :catkeys
  property :collection_ids
  property :copyright
  property :embargo_release_date, virtual: true
  property :embargo_access, virtual: true
  property :license
  property :source_id
  property :use_statement
  property :barcode
  property :view_access
  property :download_access
  property :access_location
  property :controlled_digital_lending, type: Dry::Types['params.nil'] | Dry::Types['params.bool']
  property :file_sets

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

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    super
    embargo = model.embargo
    return unless embargo

    self.embargo_release_date = embargo.release_date
    self.embargo_access = if embargo.view_access == 'location-based'
                            "loc:#{embargo.access_location}"
                          elsif embargo.download_access == 'none' && embargo.view_access.in?(%w[stanford world])
                            "#{embargo.view_access}-nd"
                          else
                            embargo.view_access
                          end
  end

  # Copies access onto the files
  def update_files
    # Convert to hash so we can mutate it
    file_sets.each do |file_set|
      file_set.files.each do |managed_file|
        case view_access
        when 'dark'
          managed_file.dark!
        when 'citation-only'
          managed_file.citation_only!
        else
          managed_file.view_access = view_access
          managed_file.download_access = download_access
          managed_file.controlled_digital_lending = controlled_digital_lending
          managed_file.access_location = access_location
        end
      end
    end
  end

  def sync
    self.download_access = 'none' if clear_download? # This must be before clearing location
    self.access_location = nil if clear_location?
    update_files if rights_changed?
    super # call super last, so all the changs are copied to the Item
  end

  def clear_download?
    %w[dark citation-only].include?(view_access)
  end

  def clear_location?
    (changed?(:view_access) || changed?(:download_access)) && view_access != 'location-based' && download_access != 'location-based'
  end

  def rights_changed?
    changed?(:view_access) || changed?(:download_access) || changed?(:location) || changed?(:controlled_digital_lending)
  end
end
