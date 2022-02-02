# frozen_string_literal: true

module Show
  class OverviewComponent < ApplicationComponent
    # @param [ArgoShowPresenter] presenter
    def initialize(presenter:)
      @presenter = presenter
      @solr_document = presenter.document
    end

    def render?
      !@presenter.cocina.is_a? NilModel
    end

    delegate :id, :status,
             :admin_policy?, :item?, :collection?, to: :@solr_document
    delegate :state_service, to: :@presenter
    delegate :allows_modification?, to: :state_service
  end
end
