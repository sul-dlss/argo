# frozen_string_literal: true

class EmbargoForm < ApplicationChangeSet
  property :release_date, virtual: true
  include HasViewAccess

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
    setup_view_access_properties(embargo)
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    unless changed?(:release_date) || changed?(:view_access) || changed?(:download_access) || changed?(:access_location)
      return
    end

    updated = model

    embargo = updated.access.embargo ? updated.access.embargo.new(embargo_params) : Cocina::Models::Embargo.new(embargo_params)
    updated_access = updated.access.new(embargo:)
    updated = updated.new(access: updated_access)

    Repository.store(updated)
  end

  def embargo_params
    {
      releaseDate: release_date,
      view: view_access,
      controlledDigitalLending: false
    }.tap do |params|
      params[:download] = download_access_valid? ? download_access : 'none'
      params[:location] = location_access_valid? ? access_location : nil
    end
  end

  private

  def download_access_valid?
    %w[citation-only dark].exclude?(view_access)
  end

  def location_access_valid?
    download_access_valid? && download_access == 'location-based'
  end
end
