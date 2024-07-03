# frozen_string_literal: true

module Show
  module Item
    class DetailsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      delegate :object_type, :created_date, :preservation_size, :doi, :orcids, to: :@solr_document
      delegate :state_service, :user_version_view?, to: :@presenter

      def catalog_record_id_label
        CatalogRecordId.label
      end

      def released_to
        @solr_document.released_to.presence&.to_sentence || 'Not released'
      end
    end
  end
end
