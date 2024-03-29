# frozen_string_literal: true

module Show
  class SourceIdComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, :source_id, :item?, to: :@document
  end
end
