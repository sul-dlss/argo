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

    delegate :filename, :mime_type, :size, :use, :publish, :shelve, :preserve, to: :file

    def view_access
      file.view_access.capitalize
    end

    def download_access
      file.download_access.capitalize
    end

    def role
      return 'No role' if use.blank?

      use.capitalize
    end

    def link_attrs
      { item_id: object_id, id: filename }
    end

    def height
      "#{file.height} px" if file.height
    end

    def width
      "#{file.width} px" if file.width
    end
  end
end
