# frozen_string_literal: true

module Show
  class IsMemberOfComponent < ApplicationComponent
    def initialize(document:, version_service:)
      @document = document
      @version_service = version_service
    end

    def collection
      return 'None selected' unless @document.collection_ids

      helpers.links_to_collections_with_objs(document: @document, value: Array(@document.collection_ids))
    end

    delegate :open_and_not_processing?, to: :@version_service
    delegate :id, to: :@document
  end
end
