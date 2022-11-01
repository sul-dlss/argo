# frozen_string_literal: true

module Show
  module Item
    class AccessRightsComponent < ApplicationComponent
      def initialize(change_set:, state_service:)
        @change_set = change_set
        @state_service = state_service
      end

      def access_rights
        return "CDL" if controlled_digital_lending

        val = "View: #{humanize_value(view_access)}"
        val += ": #{access_location}" if view_access == "location-based"
        val += ", Download: #{humanize_value(download_access)}"
        val += ": #{access_location}" if download_access == "location-based"
        val
      end

      delegate :allows_modification?, to: :@state_service
      delegate :id, :view_access, :download_access, :access_location, :controlled_digital_lending, to: :@change_set

      def humanize_value(val)
        val == "location-based" ? "Location" : val.capitalize
      end
    end
  end
end
