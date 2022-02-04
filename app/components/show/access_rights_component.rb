# frozen_string_literal: true

module Show
  class AccessRightsComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, :access_rights, :admin_policy?, to: :@document
  end
end
