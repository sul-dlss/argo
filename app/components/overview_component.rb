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

  # NOTE: that the backend will also check can?(:manage_governing_apo, object, new_apo_id), but
  # we can't do that here, since we don't yet know what APO the user might move the object to.
  # so it's possible that the user will get this button even if there are no other APOs they're
  # allowed to move the object to.
  def governing_apo_button
    render ActionButton.new(
      url: set_governing_apo_ui_item_path(id: id),
      label: 'Set governing APO',
      disabled: !state_service.allows_modification?
    )
  end

  def state_service
    @state_service ||= StateService.new(id, version: @solr_document.current_version)
  end

  delegate :id, :access_rights, :status, :copyright, :license, :use_statement, to: :@solr_document
end
