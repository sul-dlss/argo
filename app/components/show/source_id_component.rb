# frozen_string_literal: true

module Show
  class SourceIdComponent < ApplicationComponent
    def initialize(document:, presenter:)
      @document = document
      @presenter = presenter
    end

    def edit?
      item? && !version_or_user_version_view? && open_and_not_assembling?
    end

    delegate :version_service, :version_or_user_version_view?, to: :@presenter
    delegate :open_and_not_assembling?, to: :version_service
    delegate :id, :source_id, :item?, to: :@document
  end
end
