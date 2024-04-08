# frozen_string_literal: true

module Show
  module Collection
    class AccessRightsComponent < ApplicationComponent
      def initialize(change_set:, version_service:)
        @change_set = change_set
        @version_service = version_service
      end

      def access_rights
        view_access.capitalize
      end

      delegate :open?, to: :@version_service
      delegate :id, :view_access, to: :@change_set
    end
  end
end
