# frozen_string_literal: true

# determines which links display in the sidebar
class SidebarControlsComponent < ApplicationComponent
  ##
  # Ideally these methods should not make calls to external services to determine
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
  # @param [Boolean] manager
  # @param [SolrDocument] solr_document
  def initialize(manager:, solr_document:)
    @manager = manager
    @doc = solr_document
  end

  attr_reader :doc

  def manager?
    @manager
  end

  # Renders nothing if not a manager of this object
  def render?
    manager?
  end

  # a catkey indicates there's a symphony record
  def symphony_record?
    doc.catkey_id.present?
  end

  delegate :admin_policy?, :item?, :collection?, :embargoed?, to: :doc

  private

  def manage_release
    render ActionButton.new(url: item_manage_release_path(pid), label: 'Manage release')
  end

  def embargo
    return unless item?

    if embargoed?
      render ActionButton.new(url: edit_item_embargo_path(pid), label: 'Manage embargo')
    else
      render ActionButton.new(url: new_item_embargo_path(pid), label: 'Create embargo')
    end
  end

  def content_type
    render ActionButton.new(url: item_content_type_path(item_id: pid), label: 'Set content type')
  end

  def rights
    render ActionButton.new(url: rights_item_path(id: pid), label: 'Set rights')
  end

  def manage_catkey
    render ActionButton.new(url: edit_item_catkey_path(item_id: pid), label: 'Manage catkey')
  end

  def edit_collections
    render ActionButton.new(url: collection_ui_item_path(id: pid), label: 'Edit collections')
  end

  def change_source_id
    render ActionButton.new(url: source_id_ui_item_path(id: pid),
                            label: 'Change source id')
  end

  def edit_tags
    render ActionButton.new(url: edit_item_tags_path(item_id: pid),
                            label: 'Edit tags')
  end

  def edit_apo
    render ActionButton.new(
      url: edit_apo_path(pid), label: 'Edit APO', new_page: true
    )
  end

  def create_collection
    render ActionButton.new(
      url: new_apo_collection_path(apo_id: pid), label: 'Create Collection'
    )
  end

  def refresh_metadata
    render ActionButton.new(
      url: refresh_metadata_item_path(id: pid),
      method: 'post',
      label: 'Refresh descMetadata',
      new_page: true,
      disabled: !state_service.allows_modification?
    )
  end

  def close_button
    render ActionButton.new(
      url: close_ui_item_versions_path(item_id: pid),
      label: 'Close Version',
      check_url: workflow_service_closeable_path(pid)
    )
  end

  def open_button
    render ActionButton.new(
      url: open_ui_item_versions_path(item_id: pid),
      label: 'Open for modification',
      check_url: workflow_service_openable_path(pid)
    )
  end

  def reindex_button
    render ActionButton.new(
      url: dor_reindex_path(pid: pid),
      label: 'Reindex',
      new_page: true
    )
  end

  def add_workflow_button
    render ActionButton.new(
      url: new_item_workflow_path(item_id: pid), label: 'Add workflow'
    )
  end

  def republish_button
    render ActionButton.new(
      url: dor_republish_path(pid: pid),
      label: 'Republish',
      check_url: workflow_service_published_path(pid),
      new_page: true
    )
  end

  def purge_button
    render ActionButton.new(
      url: purge_item_path(id: pid),
      label: 'Purge',
      new_page: true,
      method: 'delete',
      confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
      disabled: !registered_only?
    )
  end

  # NOTE: that the backend will also check can?(:manage_governing_apo, object, new_apo_id), but
  # we can't do that here, since we don't yet know what APO the user might move the object to.
  # so it's possible that the user will get this button even if there are no other APOs they're
  # allowed to move the object to.
  def governing_apo_button
    render ActionButton.new(
      url: set_governing_apo_ui_item_path(id: pid),
      label: 'Set governing APO',
      disabled: !state_service.allows_modification?
    )
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
