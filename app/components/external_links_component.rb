# frozen_string_literal: true

class ExternalLinksComponent < ViewComponent::Base
  def initialize(document:)
    @document = document
  end

  def purl_link
    link_to 'PURL', File.join(Settings.purl_url, document.druid), target: '_blank', rel: 'noopener'
  end

  def dor_link
    link_to 'Fedora UI', File.join(Dor::Config.fedora.safeurl, "objects/#{document.id}"), target: '_blank', rel: 'noopener'
  end

  def searchworks_link
    id = document.catkey.presence || document.druid
    url = Kernel.format(Settings.searchworks_url, id: id)
    link_to 'Searchworks', url, target: '_blank', rel: 'noopener'
  end

  def index_info
    "indexed by DOR Services v#{document.dor_services_version}"
  end

  private

  attr_reader :document
end
