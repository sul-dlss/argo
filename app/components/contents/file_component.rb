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

    delegate :access, :administrative, :filename, :hasMimeType, :size, :externalIdentifier, to: :file

    def link_attrs
      { item_id: object_id, id: filename }
    end

    def routing
      [].tap do |vals|
        vals << 'publish' if administrative.publish
        vals << 'shelve' if administrative.shelve
        vals << 'preserve' if administrative.sdrPreserve
      end.join('/')
    end
  end
end
