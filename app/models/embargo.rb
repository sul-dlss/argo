# frozen_string_literal: true

class Embargo < ApplicationModel
  define_attribute_methods :release_date, :view_access, :download_access, :access_location

  attribute :release_date
  attribute :view_access
  attribute :download_access
  attribute :access_location

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.release_date = model.releaseDate
    self.view_access = model.view
    self.download_access = model.download
    self.access_location = model.location
  end
end
