# frozen_string_literal: true

module Show
  module Collection
    class DetailsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      delegate :object_type, :created_date, to: :@solr_document
      delegate :state_service, to: :@presenter

      def released_to
        @solr_document.released_to.presence&.to_sentence || 'Not released'
      end
    end
  end
end
