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
      access.view.capitalize
    end

    def download_access
      access.download.capitalize
    end

    def role
      return 'No role' if use.blank?

      use.capitalize
    end

    def link_attrs
      { item_id: object_id, id: filename }
    end

    def height
      # still need to account for no presentation
      return '' if presentation.height.blank?

      "#{presentation.height} px"
    end

    def width
      # still need to account for no presentation
      return '' if presentation.width.blank?

      "#{presentation.width} px"
    end
  end
end
