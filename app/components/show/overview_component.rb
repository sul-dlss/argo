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

    # NOTE: that the backend will also check can?(:manage_governing_apo, object, new_apo_id), but
    # we can't do that here, since we don't yet know what APO the user might move the object to.
    # so it's possible that the user will get this button even if there are no other APOs they're
    # allowed to move the object to.
    def governing_apo_button
      link_to set_governing_apo_ui_item_path(id: id),
              aria: { label: 'Set governing APO' },
              data: { controller: 'button', action: 'click->button#open' },
              class: ('disabled' unless allows_modification?).to_s do
                tag.span class: 'bi-pencil'
              end
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
