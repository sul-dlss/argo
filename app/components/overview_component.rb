# frozen_string_literal: true

class OverviewComponent < ApplicationComponent
  def initialize(solr_document:)
    @solr_document = solr_document
  end

  def admin_policy
    return unless @solr_document.apo_id

    helpers.link_to_admin_policy_with_objs(document: @solr_document, value: @solr_document.apo_id)
  end

  def collection
    helpers.links_to_collections_with_objs(document: @solr_document, value: Array(@solr_document.collection_ids))
  end

  delegate :id, :access_rights, :status, :copyright, :license, :use_statement, to: :@solr_document
end
