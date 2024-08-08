# frozen_string_literal: true

module Show
  class IsMemberOfComponent < ApplicationComponent
    def initialize(document:, presenter:)
      @document = document
      @presenter = presenter
    end

    def collection
      return 'None selected' unless @document.collection_ids

      helpers.links_to_collections_with_objs(document: @document, value: Array(@document.collection_ids))
    end

    def edit?
      !version_or_user_version_view? && open_and_not_assembling?
    end

    delegate :version_service, :version_or_user_version_view?, to: :@presenter
    delegate :open_and_not_assembling?, to: :version_service
    delegate :id, to: :@document
  end
end
