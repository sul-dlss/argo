# frozen_string_literal: true

class DownloadAllButtonComponent < ViewComponent::Base
  # @param [SolrDocument] document
  def initialize(document:)
    @document = document
  end

  def link_options
    # This onclick handler prevents the accordion which contains this element from folding.
    options = {onclick: "event.stopPropagation()"}
    return options if !document.preservation_size || document.preservation_size < 1_000_000_000

    options.merge(data: {turbo_confirm: "This will be a large download. Are you sure?"})
  end

  attr_reader :document
end
