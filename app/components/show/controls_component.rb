# frozen_string_literal: true

module Show
  # determines which controls display in the top of the page
  class ControlsComponent < ApplicationComponent
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

    delegate :admin_policy?, :agreement?, :item?, :collection?, :embargoed?, to: :doc

    private

    def manage_release
      render ActionButton.new(url: item_manage_release_path(pid), label: 'Manage release', open_modal: true)
    end

    def apply_apo_defaults
      return unless item? || collection?

      render ActionButton.new(
        url: apply_apo_defaults_item_path(id: pid),
        method: 'post',
        label: 'Apply APO defaults',
        disabled: !state_service.allows_modification?
      )
    end

    def create_embargo
      return if !item? || embargoed?

      render ActionButton.new(url: new_item_embargo_path(pid), label: 'Create embargo', open_modal: true)
    end

    def edit_apo
      render ActionButton.new(
        url: edit_apo_path(pid), label: 'Edit APO'
      )
    end

    def create_collection
      render ActionButton.new(
        url: new_apo_collection_path(apo_id: pid), label: 'Create Collection',
        open_modal: true
      )
    end

    def refresh_metadata
      render ActionButton.new(
        url: refresh_metadata_item_path(id: pid),
        method: 'post',
        label: 'Refresh descMetadata',
        disabled: !state_service.allows_modification?
      )
    end

    def reindex_button
      render ActionButton.new(
        url: dor_reindex_path(pid: pid),
        label: 'Reindex'
      )
    end

    def add_workflow_button
      render ActionButton.new(
        url: new_item_workflow_path(item_id: pid), label: 'Add workflow', open_modal: true
      )
    end

    def purge_button
      render ActionButton.new(
        url: purge_item_path(id: pid),
        label: 'Purge',
        method: 'delete',
        confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
        disabled: !registered_only?
      )
    end

    def upload_mods
      link_to 'Upload MODS', apo_bulk_jobs_path(doc), class: 'btn btn-primary'
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
end
