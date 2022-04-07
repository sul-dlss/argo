# frozen_string_literal: true

class EmbargoForm < ApplicationChangeSet
  property :release_date, virtual: true
  # TODO: Deduplicate with item_change_set
  property :view_access, virtual: true
  property :download_access, virtual: true
  property :access_location, virtual: true

  # TODO: Deduplicate with item_change_set
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
    ::ActiveModel::Name.new(nil, nil, 'Embargo')
  end

  def id
    model.externalIdentifier
  end

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    embargo = model.access.embargo
    return unless embargo

    self.release_date = embargo.releaseDate.to_date.to_fs(:default)
    self.view_access = embargo.view
    self.download_access = embargo.download
    self.access_location = embargo.location
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    return unless changed?(:release_date) || changed?(:view_access) || changed?(:download_access) || changed?(:access_location)

    updated = model
    embargo_params = {
      releaseDate: release_date,
      view: view_access,
      download: download_access,
      location: access_location
    }
    embargo = updated.access.embargo ? updated.access.embargo.new(embargo_params) : Cocina::Models::Embargo.new(embargo_params)
    updated_access = updated.access.new(embargo: embargo)
    updated = updated.new(access: updated_access)

    Repository.store(updated)
  end
end
