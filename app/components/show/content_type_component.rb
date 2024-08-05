# frozen_string_literal: true

module Show
  class ContentTypeComponent < ApplicationComponent
    def initialize(document:, presenter:)
      @document = document
      @presenter = presenter
    end

    def edit?
      !version_or_user_version_view? && open_and_not_assembling?
    end

    delegate :version_service, :version_or_user_version_view?, :change_set, to: :@presenter
    delegate :open_and_not_assembling?, to: :version_service
    delegate :id, :content_type, to: :@document
  end
end
