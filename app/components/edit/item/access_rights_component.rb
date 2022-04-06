# frozen_string_literal: true

module Edit
  module Item
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
    end
  end
end
