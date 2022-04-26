# frozen_string_literal: true

module Create
  module Item
    # This is the access rights for the registration form
    class AccessRightsComponent < Edit::Item::AccessRightsComponent
      def initialize(form_builder:)
        @form_builder = form_builder
      end

      def f
        @form_builder
      end

      def view_label(value)
        label = super
        label += ' (APO default)' if f.object.view_access == value
        label
      end

      def download_label(value)
        label = super
        label += ' (APO default)' if f.object.download_access == value
        label
      end

      def location_label(value)
        label = super
        label += ' (APO default)' if f.object.access_location == value
        label
      end

      def cdl_label(value)
        label = super
        label += ' (APO default)' if f.object.controlled_digital_lending == value
        label
      end
    end
  end
end
