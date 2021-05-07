# frozen_string_literal: true

# This draws links to external services for this object. Used on the sidebar of the item show page.
class ExternalLinksComponent < ViewComponent::Base
  # @param [SolrDocument] document
  def initialize(document:)
    @document = document
  end

  def purl_link
    link_to 'PURL', File.join(Settings.purl_url, document.druid),
            target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def dor_link
    link_to 'Fedora UI', File.join(fedora_url_without_credentials, "objects/#{document.id}"),
            target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def searchworks_link
    id = document.catkey.presence || document.druid
    url = Kernel.format(Settings.searchworks_url, id: id)
    link_to 'Searchworks', url, target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def foxml_link
    url = File.join(fedora_url_without_credentials, "objects/#{document.id}/export?context=archive")
    link_to 'FoXML', url, target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def solr_link
    link_to 'Solr document', solr_document_path(document, format: :json),
            target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def cocina_link
    link_to 'Cocina model', item_path(document, format: :json),
            target: '_blank', rel: 'noopener', class: 'nav-link'
  end

  def released_to_searchworks?
    document.released_to.include?('Searchworks')
  end

  private

  attr_reader :document

  def fedora_url_without_credentials
    fedora_uri = URI.parse(Settings.fedora_url)
    fedora_uri.user = fedora_uri.password = nil
    fedora_uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
