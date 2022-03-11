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
        ['Apply APO defaults  ', 'ApplyApoDefaultsJob'],
        ['Manage release', 'ReleaseObjectJob'],
        %w[Reindex RemoteIndexingJob],
        ['Republish objects', 'RepublishJob'],
        ['Purge object', 'PurgeJob'],
        ['Add workflow', 'AddWorkflowJob']
      ]],
      ['Modify objects (via form)', [
        ['Open new object versions', 'PrepareJob'],
        ['Close versions', 'CloseVersionJob'],
        ['Update governing APO', 'SetGoverningApoJob'],
        ['Edit Catkeys and Barcodes', 'SetCatkeysAndBarcodesJob'],
        ['Edit License and Rights Statements', 'SetLicenseAndRightsStatementsJob'],
        ['Refresh MODS', 'RefreshModsJob'],
        ['Set Content Type', 'SetContentTypeJob'],
        ['Set Collection', 'SetCollectionJob'],
        ['Set object rights', 'SetRightsJob']
      ]],
      ['Modify objects (via CSV)', [
        ['Create virtual object(s)', 'CreateVirtualObjectsJob'],
        ['Edit Catkeys and Barcodes from CSV', 'SetCatkeysAndBarcodesCsvJob'],
        ['Edit Source ID from CSV', 'SetSourceIdsCsvJob'],
        ['Export tags to CSV', 'ExportTagsJob'],
        ['Import tags from CSV', 'ImportTagsJob'],
        ['Export structural metadata to CSV', 'ExportStructuralJob'],
        ['Manage embargo', 'ManageEmbargoesJob'],
        ['Register Druids', 'RegisterDruidsJob']
      ]],
      ['Generate reports', [
        ['Download descriptive metadata', 'DescmetadataDownloadJob'],
        ['Checksum report', 'ChecksumReportJob']
      ]]
    ]
  end
end
