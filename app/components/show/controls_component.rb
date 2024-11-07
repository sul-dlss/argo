# frozen_string_literal: true

module Show
  # determines which controls display in the top of the page
  # rubocop:disable Metrics/ClassLength
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
    #
    # @param [Boolean] manager
    # @param [ArgoShowPresenter] presenter
    def initialize(manager:, presenter:)
      @manager = manager
      @presenter = presenter
      @doc = presenter.document
      @user_versions_presenter = presenter.user_versions_presenter
    end

    attr_reader :doc, :presenter, :user_versions_presenter

    def manager?
      @manager
    end

    # Renders nothing if not a manager of this object
    def render?
      manager?
    end

    # a catalog record ID indicates there's a catalog record
    def catalog_record?
      doc.catalog_record_id.present?
    end

    delegate :admin_policy?, :agreement?, :item?, :collection?, :embargoed?, to: :doc
    delegate :open?, :openable?, :open_and_not_assembling?, :user_version_view, :version_or_user_version_view?,
             :user_version_view?, :version_view?, :version_view, to: :presenter

    def button_disabled?
      !open_and_not_assembling? || version_or_user_version_view?
    end

    def collection_button_disabled?
      !open? && !openable?
    end

    def refresh_button_label
      'Refresh'
    end

    private

    def manage_release
      render ActionButton.new(
        url: item_manage_release_path(druid),
        label: 'Manage release',
        open_modal: true,
        disabled: version_or_user_version_view?
      )
    end

    def apply_apo_defaults
      return unless item? || collection?

      render ActionButton.new(
        url: apply_apo_defaults_item_path(id: druid),
        method: 'post',
        label: 'Apply APO defaults',
        disabled: button_disabled?
      )
    end

    def create_embargo
      return if !item? || embargoed?

      render ActionButton.new url: new_item_embargo_path(druid),
                              label: 'Create embargo',
                              open_modal: true,
                              disabled: button_disabled?
    end

    def create_text_extraction
      return unless Settings.features.ocr_workflow || Settings.features.speech_to_text_workflow
      return unless TextExtraction.new(presenter.cocina).possible? && !registered_only?

      render ActionButton.new url: new_item_text_extraction_path(druid),
                              label: 'Text extraction',
                              open_modal: true,
                              disabled: in_accessioning? || button_disabled?
    end

    def edit_apo
      render ActionButton.new(
        url: edit_apo_path(druid),
        label: 'Edit APO',
        disabled: button_disabled?
      )
    end

    def create_collection
      render ActionButton.new(
        url: new_apo_collection_path(apo_id: druid), label: 'Create Collection',
        open_modal: true,
        disabled: collection_button_disabled?
      )
    end

    def reindex_button
      render ActionButton.new(
        url: dor_reindex_path(druid:),
        label: 'Reindex',
        disabled: version_or_user_version_view?
      )
    end

    def add_workflow_button
      render ActionButton.new(
        url: new_item_workflow_path(item_id: druid),
        label: 'Add workflow',
        open_modal: true,
        disabled: button_disabled?
      )
    end

    def purge_button
      render ActionButton.new(
        url: purge_item_path(id: druid),
        label: 'Purge',
        method: 'delete',
        confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
        disabled: !registered_only? || version_or_user_version_view?
      )
    end

    def republish_button
      render ActionButton.new(
        url: item_publish_path(doc),
        label: 'Republish',
        method: 'post',
        disabled: !published? || version_or_user_version_view?
      )
    end

    def withdraw_or_restore
      return unless item?

      if user_versions_presenter.user_version_withdrawable?
        render ActionButton.new(
          url: withdraw_item_public_version_path(doc, user_version_view),
          label: 'Withdraw',
          method: 'post',
          confirm: 'Once you withdraw this version, the Purl will no longer display it. Are you sure? '
        )
      elsif user_versions_presenter.user_version_restorable?
        render ActionButton.new(
          url: restore_item_public_version_path(doc, user_version_view),
          label: 'Restore',
          method: 'post'
        )
      end
    end

    def upload_mods
      link_to 'Upload MODS', apo_bulk_jobs_path(doc), class: 'btn btn-primary'
    end

    def download_cocina_path
      if version_view?
        descriptive_item_version_path(doc, version_view, format: :csv)
      elsif user_version_view?
        descriptive_item_public_version_path(doc, user_version_view, format: :csv)
      else
        item_descriptive_path(doc, format: :csv)
      end
    end

    def druid
      @druid ||= doc['id']
    end

    def registered_only?
      ['Registered', 'Unknown Status'].include?(doc['processing_status_text_ssi'])
    end

    def in_accessioning?
      doc['processing_status_text_ssi']&.include?('In accessioning')
    end

    def published?
      doc[SolrDocument::FIELD_LAST_PUBLISHED_DATE].present?
    end
  end
  # rubocop:enable Metrics/ClassLength
end
