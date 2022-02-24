# frozen_string_literal: true

module Show
  module Agreement
    class DetailsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      delegate :object_type, :created_date, :preservation_size, to: :@solr_document
      delegate :state_service, to: :@presenter
    end
  end
end
