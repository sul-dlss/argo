# frozen_string_literal: true

class BulkActionsFormComponent < ApplicationComponent
  def initialize(form:, last_search:)
    @form = form
    @last_search = last_search
  end

  ##
  # Add a pids_only=true parameter to create a "search of pids" to an existing
  # Blacklight::Search
  # This is used by the "Populate with previous search" feature of bulk actions
  # @param [Blacklight::Search, nil]
  # @return [Hash]
  def search_of_pids
    return '' if @last_search.blank?

    @last_search.query_params.merge('pids_only' => true)
  end

  def action_types
    grouped_options_for_select [
      ['Perform actions', [
        ['Manage release', 'ReleaseObjectJob'],
        %w[Reindex RemoteIndexingJob],
        ['Republish objects', 'RepublishJob'],
        ['Purge object', 'PurgeJob']
      ]],
      ['Modify objects (via form)', [
        ['Open new object versions', 'PrepareJob'],
        ['Close versions', 'CloseVersionJob'],
        ['Update governing APO', 'SetGoverningApoJob'],
        ['Edit Catkeys and Barcodes', 'SetCatkeysAndBarcodesJob'],
        ['Edit License and Rights Statements', 'SetLicenseAndRightsStatementsJob']
      ]],
      ['Modify objects (via CSV)', [
        ['Create virtual object(s)', 'CreateVirtualObjectsJob'],
        ['Edit Catkeys and Barcodes from CSV', 'SetCatkeysAndBarcodesCsvJob'],
        ['Export tags to CSV', 'ExportTagsJob'],
        ['Import tags from CSV', 'ImportTagsJob'],
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
