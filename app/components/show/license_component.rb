# frozen_string_literal: true

module Show
  class LicenseComponent < ApplicationComponent
    def initialize(change_set:, state_service:)
      @change_set = change_set
      @state_service = state_service
    end

    def license
      uri = @change_set.license
      return 'No license' unless uri

      value = Constants::LICENSE_OPTIONS.find { |attribute| attribute.fetch(:uri) == uri }
      value.fetch(:label)
    end

    delegate :open?, to: :@state_service
    delegate :id, to: :@change_set
  end
end
