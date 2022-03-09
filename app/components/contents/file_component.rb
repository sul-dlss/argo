# frozen_string_literal: true

module Contents
  class FileComponent < ViewComponent::Base
    def initialize(file:, object_id:, viewable:)
      @file = file
      @object_id = object_id
      @viewable = viewable
    end

    attr_reader :file, :object_id

    def viewable?
      @viewable
    end

    delegate :access, :administrative, :filename, :hasMimeType, :size, :externalIdentifier, :use, to: :file
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
  end
end
