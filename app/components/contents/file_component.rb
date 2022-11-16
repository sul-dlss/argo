# frozen_string_literal: true

module Contents
  class FileComponent < ViewComponent::Base
    def initialize(file:, object_id:, viewable:, image:)
      @file = file
      @object_id = object_id
      @viewable = viewable
      @image = image
    end

    attr_reader :file, :object_id

    def viewable?
      @viewable
    end

    def image?
      @image
    end

    delegate :access, :administrative, :filename, :hasMimeType, :size, :externalIdentifier, :use, :presentation, to: :file
    delegate :publish, :shelve, :sdrPreserve, to: :administrative

    def view_access
      if access.view == "location-based"
        access.location
      else
        access.view.capitalize
      end
    end

    def download_access
      if access.download == "location-based"
        access.location
      else
        access.download.capitalize
      end
    end

    def role
      return "No role" if use.blank?

      use.capitalize
    end

    def link_attrs
      {item_id: object_id, id: filename}
    end

    def height
      return "" if presentation&.height.blank?

      "#{presentation.height} px"
    end

    def width
      return "" if presentation&.width.blank?

      "#{presentation.width} px"
    end
  end
end
