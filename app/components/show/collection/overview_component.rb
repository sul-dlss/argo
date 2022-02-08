# frozen_string_literal: true

module Show
  module Collection
    class OverviewComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      delegate :id, :status, to: :@solr_document
      delegate :state_service, to: :@presenter
    end
  end
end
