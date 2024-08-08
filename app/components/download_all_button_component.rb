# frozen_string_literal: true

class DownloadAllButtonComponent < ViewComponent::Base
  # @param [SolrDocument] document
  def initialize(presenter:, document:)
    @document = document
    @presenter = presenter
  end

  def link_options
    # This onclick handler prevents the accordion which contains this element from folding.
    options = { onclick: 'event.stopPropagation()' }
    return options if !document.preservation_size || document.preservation_size < 1_000_000_000

    options.merge(data: { turbo_confirm: 'This will be a large download. Are you sure?' })
  end

  def render?
    WorkflowService.accessioned?(druid: cocina.externalIdentifier) && !version_view?
  end

  def path
    user_version_view? ? download_item_user_version_files_path(document.id, user_version_view) : download_item_files_path(document)
  end

  attr_reader :document, :presenter

  delegate :cocina, :user_version_view?, :user_version_view, :version_view?, to: :presenter
end
