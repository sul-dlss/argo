# frozen_string_literal: true

module Show
  module Apo
    class DetailsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      delegate :created_date, :id, to: :@solr_document
    end
  end
end
