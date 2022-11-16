# frozen_string_literal: true

module Edit
  module Item
    # This is the access rights for the edit form
    class AccessRightsComponent < ApplicationComponent
      def initialize(form_builder:, include_cdl: true)
        @form_builder = form_builder
        @include_cdl = include_cdl
      end

      def f
        @form_builder
      end

      # embargo form doesn't have CDL access
      def include_cdl?
        @include_cdl
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def view_label(value)
        value.tr("-", " ").capitalize
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def download_label(value)
        value.tr("-", " ").capitalize
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def location_label(value)
        value
      end

      # This may be overriden in Create::Item::AccessRightsComponent (for registration)
      def cdl_label(value)
        value ? "Yes" : "No"
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

      def cdl_labels
        Constants::CDL_OPTIONS.map do |value|
          [cdl_label(value), value]
        end
      end
    end
  end
end
