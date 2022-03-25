# frozen_string_literal: true

module Show
  module Collection
    class AccessRightsComponent < ApplicationComponent
      def initialize(change_set:, state_service:)
        @change_set = change_set
        @state_service = state_service
      end

      def access_rights
        view_access.capitalize
      end

      delegate :allows_modification?, to: :@state_service
      delegate :id, :view_access, to: :@change_set
    end
  end
end
