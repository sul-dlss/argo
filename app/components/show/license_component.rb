# frozen_string_literal: true

module Show
  class LicenseComponent < ApplicationComponent
    def initialize(change_set:, version_service:)
      @change_set = change_set
      @version_service = version_service
    end

    def license
      uri = @change_set.license
      return 'No license' unless uri

      value = Constants::LICENSE_OPTIONS.find { |attribute| attribute.fetch(:uri) == uri }
      value.fetch(:label)
    end

    delegate :open?, to: :@version_service
    delegate :id, to: :@change_set
  end
end
