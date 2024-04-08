# frozen_string_literal: true

module Show
  module Apo
    class OverviewComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
        @registration_workflow = presenter.cocina.administrative.registrationWorkflow
      end

      def registration_workflow
        @registration_workflow.present? ? @registration_workflow.join(', ') : 'None'
      end

      delegate :id, :status, to: :@solr_document
    end
  end
end
