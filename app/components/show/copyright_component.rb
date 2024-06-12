# frozen_string_literal: true

module Show
  class CopyrightComponent < ApplicationComponent
    def initialize(change_set:, version_service:)
      @change_set = change_set
      @version_service = version_service
    end

    def copyright
      @change_set.copyright || 'Not entered'
    end

    delegate :open_and_not_processing?, to: :@version_service
    delegate :id, to: :@change_set
  end
end
