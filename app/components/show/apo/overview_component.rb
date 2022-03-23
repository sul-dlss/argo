# frozen_string_literal: true

module Show
  module Apo
    class OverviewComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
        @registration_workflows = presenter.item.registration_workflows
      end

      def registration_workflow
        @registration_workflows.present? ? @registration_workflows.join(', ') : 'None'
      end

      delegate :id, :status, to: :@solr_document
      delegate :state_service, to: :@presenter
    end
  end
end
