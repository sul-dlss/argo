# frozen_string_literal: true

class ManagedFile < ApplicationModel
  define_attribute_methods :view_access, :download_access, :access_location,
                           :controlled_digital_lending, :publish, :shelve, :preserve,
                           :filename, :mime_type, :size, :use, :height, :width

  attribute :view_access
  attribute :download_access
  attribute :access_location
  attribute :controlled_digital_lending
  attribute :publish
  attribute :shelve
  attribute :preserve
  attribute :filename
  attribute :mime_type
  attribute :size
  attribute :use
  attribute :height
  attribute :width

  # When the object is initialized, copy the properties from the cocina model to the entity:
  def setup_properties!
    self.filename = model.filename
    self.mime_type = model.hasMimeType
    self.size = model.size
    self.use = model.use

    self.view_access = model.access.view
    self.download_access = model.access.download
    self.access_location = model.access.location
    self.controlled_digital_lending = model.access.controlledDigitalLending

    self.publish = model.administrative.publish
    self.shelve = model.administrative.shelve
    self.preserve = model.administrative.sdrPreserve

    self.height = model.presentation&.height
    self.width = model.presentation&.width
  end

  def administrative_changed?
    publish_changed? || shelve_changed? || preserve_changed?
  end

  # Assigns the correct access and ensures publsh and shelve are false
  def dark!
    citation_only!
    self.publish = false
    self.shelve = false
  end

  # Assigns the correct access so the object shows on PURL, but doesn't reveal any files
  def citation_only!
    self.view_access = 'dark'
    self.download_access = 'none'
    self.controlled_digital_lending = false
    self.access_location = nil
  end
end
