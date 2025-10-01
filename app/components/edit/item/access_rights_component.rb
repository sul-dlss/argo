# frozen_string_literal: true

module Edit
  module Item
    # This is the access rights for the edit form
    class AccessRightsComponent < ApplicationComponent
      def initialize(form_builder:)
        @form_builder = form_builder
      end

      def f
        @form_builder
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def view_label(value)
        value.tr('-', ' ').capitalize
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def download_label(value)
        value.tr('-', ' ').capitalize
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def location_label(value)
        value
      end

      def view_labels
        Constants::VIEW_ACCESS_OPTIONS.map do |value|
          [view_label(value), value]
        end
      end

      def download_labels
        Constants::DOWNLOAD_ACCESS_OPTIONS.map do |value|
          [download_label(value), value]
        end
      end

      def location_labels
        Constants::ACCESS_LOCATION_OPTIONS.map do |value|
          [location_label(value), value]
        end
      end
    end
  end
end
