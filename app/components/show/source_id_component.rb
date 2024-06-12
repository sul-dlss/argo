# frozen_string_literal: true

module Show
  class SourceIdComponent < ApplicationComponent
    def initialize(document:, version_service:)
      @document = document
      @version_service = version_service
    end

    delegate :open_and_not_processing?, to: :@version_service
    delegate :id, :source_id, :item?, to: :@document
  end
end
