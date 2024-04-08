# frozen_string_literal: true

module Show
  class ContentTypeComponent < ApplicationComponent
    def initialize(document:, version_service:)
      @document = document
      @version_service = version_service
    end

    delegate :open?, to: :@version_service
    delegate :id, :content_type, to: :@document
  end
end
