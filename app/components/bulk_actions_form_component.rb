# frozen_string_literal: true

class BulkActionsFormComponent < ApplicationComponent
  def initialize(form:)
    @form = form
  end

  ##
  # Add a pids_only=true parameter to create a "search of pids" to an existing
  # Blacklight::Search
  # This is used by the "Populate with previous search" feature of bulk actions
  # @param [Blacklight::Search, nil]
  # @return [Hash]
  def search_of_pids
    return '' unless search_state.has_constraints?

    search_state.params_for_search('pids_only' => true)
  end

  def action_types
    grouped_options_for_select [
      ['Perform actions', [
        ['Manage release', 'ReleaseObjectJob'],
        %w[Reindex RemoteIndexingJob],
        ['Republish objects', 'RepublishJob'],
        %w[Purge PurgeJob],
        ['Add workflow', 'AddWorkflowJob']
      ]],
      ['Modify objects (via form)', [
        ['Open new object versions', 'PrepareJob'],
        ['Close objects', 'CloseVersionJob'],
        ['Update governing APO', 'SetGoverningApoJob'],
        ['Apply APO defaults', 'ApplyApoDefaultsJob'],
        ['Set object rights', 'SetRightsJob'],
        ['Edit license and rights statements', 'SetLicenseAndRightsStatementsJob'],
        ['Edit catkeys and barcodes', 'SetCatkeysAndBarcodesJob'],
        ['Refresh MODS from catkey', 'RefreshModsJob'],
        ['Set content type', 'SetContentTypeJob'],
        ['Set collection', 'SetCollectionJob']
      ]],
      ['Modify objects (via CSV)', [
        ['Create virtual object(s)', 'CreateVirtualObjectsJob'],
        ['Edit catkeys and barcodes from CSV', 'SetCatkeysAndBarcodesCsvJob'],
        ['Change source id', 'SetSourceIdsCsvJob'],
        ['Export tags to CSV', 'ExportTagsJob'],
        ['Import tags from CSV', 'ImportTagsJob'],
        ['Export structural metadata', 'ExportStructuralJob'],
        ['Manage embargo', 'ManageEmbargoesJob'],
        ['Register druids', 'RegisterDruidsJob']
      ]],
      ['Generate reports', [
        ['Download checksum report', 'ChecksumReportJob'],
        ['Download descriptive metadata (as MODS)', 'DescmetadataDownloadJob']
      ]]
    ]
  end
end
