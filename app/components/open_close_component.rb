# frozen_string_literal: true

class OpenCloseComponent < ApplicationComponent
  # @param [SolrDocument] solr_document
  def initialize(solr_document:)
    @solr_document = solr_document
  end

  def close_button
    link_to '🔓', close_ui_item_versions_path(item_id: id),
            title: 'Close Version',
            class: 'btn',
            hidden: true,
            data: {
              controller: 'open-close',
              open_close_url_value: workflow_service_closeable_path(id)
            }
  end

  def open_button
    link_to '🔒', open_ui_item_versions_path(item_id: id),
            title: 'Open for modification',
            class: 'btn',
            hidden: true,
            data: {
              controller: 'open-close',
              open_close_url_value: workflow_service_openable_path(id)
            }
  end

  attr_reader :solr_document

  delegate :id, to: :solr_document
end
