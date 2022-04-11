# frozen_string_literal: true

module HasViewAccess
  extend ActiveSupport::Concern

  included do
    property :view_access, virtual: true
    property :download_access, virtual: true
    property :access_location, virtual: true

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
  end

  def setup_view_access_properties(access_model)
    self.view_access = access_model.view
    self.download_access = access_model.download
    self.access_location = access_model.location
  end
end
