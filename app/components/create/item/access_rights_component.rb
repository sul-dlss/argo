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
        label += " (APO default)" if access_template.default_view?(value)
        label
      end

      def download_label(value)
        label = super
        label += " (APO default)" if access_template.default_download?(value)
        label
      end

      def location_label(value)
        label = super
        label += " (APO default)" if access_template.default_location?(value)
        label
      end

      def cdl_label(value)
        label = super
        label += " (APO default)" if access_template.default_controlled_digital_lending?(value)
        label
      end

      private

      def access_template
        f.object
      end
    end
  end
end
