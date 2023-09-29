# frozen_string_literal: true

module Show
  module Apo
    class DefaultObjectRightsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @default_access = @presenter.cocina.administrative.accessTemplate
      end

      def access_rights
        @presenter.document.default_access_rights
      end

      def copyright
        @default_access.copyright || 'None'
      end

      def license
        @default_access.license || 'None'
      end

      def use_and_reproduction
        @default_access.useAndReproductionStatement || 'None'
      end
    end
  end
end
