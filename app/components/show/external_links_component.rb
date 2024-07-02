# frozen_string_literal: true

module Show
  # This draws links to external services for this object. Used on the sidebar of the item show page.
  class ExternalLinksComponent < ViewComponent::Base
    # @param [SolrDocument] document
    # @param [ArgoShowPresenter] presenter
    def initialize(document:, presenter:)
      @document = document
      @presenter = presenter
    end

    delegate :publishable?, to: :@document
    delegate :user_version_view?, :user_version, to: :@presenter

    def purl_link
      link_to 'PURL', File.join(Settings.purl_url, document.druid),
              target: '_blank', rel: 'noopener', class: 'external-link-button'
    end

    def searchworks_link
      return tag.span('SearchWorks', class: 'external-link-button disabled btn') unless released_to_searchworks?

      id = document.catalog_record_id.presence || document.druid
      url = Kernel.format(Settings.searchworks_url, id:)
      link_to 'SearchWorks', url, target: '_blank', rel: 'noopener', class: 'external-link-button'
    end

    def solr_link
      link_to 'Solr document', solr_document_path(document, format: :json),
              target: '_blank', rel: 'noopener', class: 'external-link-button'
    end

    def cocina_link
      path = user_version_view? ? item_user_version_path(document.id, user_version, format: :json) : item_path(document, format: :json)
      link_to 'Cocina model',
              path,
              target: '_blank',
              rel: 'noopener',
              class: 'external-link-button'
    end

    def description_link
      link_to 'Description', description_link_path,
              class: 'external-link-button',
              data: { blacklight_modal: 'trigger' }
    end

    def description_link_path
      user_version_view? ? descriptive_item_user_version_metadata_path(document.id, user_version) : descriptive_item_metadata_path(document.id)
    end

    def released_to_searchworks?
      document.released_to.include?('Searchworks')
    end

    private

    attr_reader :document, :presenter
  end
end
