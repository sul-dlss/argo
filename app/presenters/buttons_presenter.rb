# frozen_string_literal: true

# determines which links display in the sidebar
class ButtonsPresenter
  # @param [Boolean] manager
  # @param [SolrDocument] solr_document
  def initialize(manager:, solr_document:)
    @manager = manager
    @doc = solr_document
  end

  attr_reader :manager, :doc

  delegate :close_ui_item_versions_path,
           :workflow_service_closeable_path,
           :workflow_service_openable_path,
           :open_ui_item_versions_path,
           :edit_apo_path,
           :new_apo_collection_path,
           :dor_reindex_path,
           :set_governing_apo_ui_item_path,
           :new_item_workflow_path,
           :workflow_service_published_path,
           :purge_item_path,
           :source_id_ui_item_path,
           :edit_item_tags_path,
           :catkey_ui_item_path,
           :collection_ui_item_path,
           :item_content_type_path,
           :rights_item_path,
           :refresh_metadata_item_path,
           :item_manage_release_path,
           :embargo_form_item_path,
           :dor_republish_path,
           to: :url_helpers

  def url_helpers
    Rails.application.routes.url_helpers
  end

  ##
  # Ideally this method should not make calls to external services to determine
  # what buttons should be rendered. These external requests are blocking and
  # will not allow the page to load until all requests are finished.
  #
  # Instead, use the `check_url` field to specify an endpoint for what'd be a blocking request
  # to determine whether the button should be enabled.  The button will start out disabled,
  # and will be enabled (or not) depending on the response from the call out to `check_url`.
  #
  # If you can determine whether the button should be disabled based on information that's
  # already available, without making a blocking request, you can use the `disabled` field
  # to just permanantly disable the button without calling out to a `check_url`.  Note that
  # you should not need to use both fields, since use of `check_url` disables the button at
  # first anyway.
  #
  # @return [Array]
  def buttons
    return [] unless manager

    buttons = [close_button, open_button]

    if doc.admin_policy?
      buttons << { url: edit_apo_path(pid), label: 'Edit APO', new_page: true }
      buttons << { url: new_apo_collection_path(apo_id: pid), label: 'Create Collection' }
    end

    buttons << reindex_button
    buttons << governing_apo_button
    buttons << add_workflow_button
    buttons << republish_button
    buttons << purge_button

    buttons << { url: source_id_ui_item_path(id: pid), label: 'Change source id' }
    buttons << { url: edit_item_tags_path(item_id: pid), label: 'Edit tags' }
    if doc.item? || doc.collection?
      buttons << { url: catkey_ui_item_path(id: pid), label: 'Manage catkey' }
      buttons << { url: collection_ui_item_path(id: pid), label: 'Edit collections' }
    end

    buttons << { url: item_content_type_path(item_id: pid), label: 'Set content type' } if doc.item?
    buttons << { url: rights_item_path(id: pid), label: 'Set rights' } unless doc.admin_policy?

    if doc.catkey_id
      # a catkey indicates there's a symphony record
      buttons << refresh_metadata_button
    end
    buttons << { url: item_manage_release_path(pid), label: 'Manage release' }

    # TODO: add a date picker and button to change the embargo date for those who should be able to.
    buttons << { label: 'Update embargo', url: embargo_form_item_path(pid) } if doc.embargoed?

    buttons
  end

  private

  def refresh_metadata_button
    {
      url: refresh_metadata_item_path(id: pid),
      method: 'post',
      label: 'Refresh descMetadata',
      new_page: true,
      disabled: !state_service.allows_modification?
    }
  end

  def close_button
    {
      url: close_ui_item_versions_path(item_id: pid),
      label: 'Close Version',
      check_url: workflow_service_closeable_path(pid)
    }
  end

  def open_button
    {
      url: open_ui_item_versions_path(item_id: pid),
      label: 'Open for modification',
      check_url: workflow_service_openable_path(pid)
    }
  end

  def reindex_button
    {
      url: dor_reindex_path(pid: pid),
      label: 'Reindex',
      new_page: true
    }
  end

  def add_workflow_button
    { url: new_item_workflow_path(item_id: pid), label: 'Add workflow' }
  end

  def republish_button
    {
      url: dor_republish_path(pid: pid),
      label: 'Republish',
      check_url: workflow_service_published_path(pid),
      new_page: true
    }
  end

  def purge_button
    {
      url: purge_item_path(id: pid),
      label: 'Purge',
      new_page: true,
      method: 'delete',
      confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
      disabled: !registered_only?
    }
  end

  # note that the backend will also check can?(:manage_governing_apo, object, new_apo_id), but
  # we can't do that here, since we don't yet know what APO the user might move the object to.
  # so it's possible that the user will get this button even if there are no other APOs they're
  # allowed to move the object to.
  def governing_apo_button
    {
      url: set_governing_apo_ui_item_path(id: pid),
      label: 'Set governing APO',
      disabled: !state_service.allows_modification?
    }
  end

  def pid
    @pid ||= doc['id']
  end

  def state_service
    @state_service ||= StateService.new(pid, version: doc.current_version)
  end

  def registered_only?
    ['Registered', 'Unknown Status'].include?(doc['processing_status_text_ssi'])
  end
end
