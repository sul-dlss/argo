# frozen_string_literal: true

module Edit
  module Item
    class AccessRightsComponent < ApplicationComponent
      def initialize(form_builder:)
        @form_builder = form_builder
      end

      def f
        @form_builder
      end
    end
  end
end
