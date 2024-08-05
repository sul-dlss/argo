# frozen_string_literal: true

module Show
  module Item
    class AccessRightsComponent < ApplicationComponent
      def initialize(presenter:)
        @presenter = presenter
      end

      def access_rights
        return 'CDL' if controlled_digital_lending

        val = "View: #{humanize_value(view_access)}"
        val += ": #{access_location}" if view_access == 'location-based'
        val += ", Download: #{humanize_value(download_access)}"
        val += ": #{access_location}" if download_access == 'location-based'
        val
      end

      def edit?
        !version_or_user_version_view? && open_and_not_assembling?
      end

      delegate :version_service, :version_or_user_version_view?, :change_set, to: :@presenter
      delegate :open_and_not_assembling?, to: :version_service
      delegate :id, :view_access, :download_access, :access_location, :controlled_digital_lending, to: :change_set

      def humanize_value(val)
        val == 'location-based' ? 'Location' : val.capitalize
      end
    end
  end
end
