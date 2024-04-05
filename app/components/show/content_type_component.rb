# frozen_string_literal: true

module Show
  class ContentTypeComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    delegate :open?, to: :@state_service
    delegate :id, :content_type, to: :@document
  end
end
