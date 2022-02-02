# frozen_string_literal: true

module Show
  class IsMemberOfComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    def collection
      return 'None selected' unless @document.collection_ids

      helpers.links_to_collections_with_objs(document: @document, value: Array(@document.collection_ids))
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, to: :@document
  end
end
