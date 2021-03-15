# frozen_string_literal: true

module Contents
  class FileComponent < ViewComponent::Base
    def initialize(file:, viewable:)
      @file = file
      @viewable = viewable
    end

    attr_reader :file

    def viewable?
      @viewable
    end

    delegate :access, :administrative, :filename, :hasMimeType, :size, :externalIdentifier, to: :file

    def link_attrs
      # TODO: we should avoid having to parse meaning out of identifiers
      object_id, file_id = externalIdentifier.split('/')
      { item_id: object_id, id: file_id }
    end

    def routing
      [].tap do |vals|
        vals << 'publish' if access.access == 'world' # TODO: change this when publish is added to cocina
        vals << 'shelve' if administrative.shelve
        vals << 'preserve' if administrative.sdrPreserve
      end.join('/')
    end
  end
end
