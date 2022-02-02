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

    def admin_policy
      return unless @solr_document.apo_id

      helpers.link_to_admin_policy_with_objs(document: @solr_document, value: @solr_document.apo_id)
    end

    def collection
      return 'None selected' unless @solr_document.collection_ids

      helpers.links_to_collections_with_objs(document: @solr_document, value: Array(@solr_document.collection_ids))
    end

    def rights
      link_to rights_item_path(id: id),
              aria: { label: 'Set rights' },
              data: { controller: 'button', action: 'click->button#open' } do
                tag.span class: 'bi-pencil'
              end
    end

    def edit_collections
      link_to collection_ui_item_path(id: id),
              aria: { label: 'Edit collections' },
              data: { controller: 'button', action: 'click->button#open' } do
                tag.span class: 'bi-pencil'
              end
    end

    delegate :id, :access_rights, :status,
             :admin_policy?, :item?, :collection?, to: :@solr_document
    delegate :state_service, to: :@presenter
    delegate :allows_modification?, to: :state_service
  end
end
