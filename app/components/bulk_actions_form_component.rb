# frozen_string_literal: true

class BulkActionsFormComponent < ApplicationComponent
  ##
  # Add a druids_only=true parameter to create a "search of druids" to an existing
  # Blacklight::Search
  # This is used by the "Populate with previous search" feature of bulk actions
  # @param [Blacklight::Search, nil]
  # @return [Hash]
  def search_of_druids
    return {} unless search_state.has_constraints?

    search_state.params_for_search('druids_only' => true)
  end

  def action_types
    grouped_options_for_select [
      ['Perform actions', [
        ['Manage release', new_manage_release_job_path(search_of_druids)],
        ['Republish', new_republish_job_path(search_of_druids)],
        ['Reindex', new_reindex_job_path(search_of_druids)]
      ]],
      ['Modify objects', [
        ['Open new version', new_open_version_job_path(search_of_druids)],
        ['Close version', new_close_version_job_path(search_of_druids)],
        ['Add workflow', new_add_workflow_job_path(search_of_druids)],
        ['Text extraction (not available yet)', new_text_extraction_job_path(search_of_druids)],
        ['Register new druids (via CSV)', new_register_druid_job_path],
        ['Purge', new_purge_job_path(search_of_druids)]
      ]],
      ['Manage descriptive metadata', [
        ['Refresh metadata from FOLIO record', new_refresh_mods_job_path(search_of_druids)],
        ['Download descriptive metadata spreadsheet', new_descriptive_metadata_export_job_path(search_of_druids)],
        ['Validate descriptive metadata spreadsheet', new_validate_cocina_descriptive_job_path],
        ['Upload descriptive metadata spreadsheet', new_descriptive_metadata_import_job_path(search_of_druids)],
        ['Export FOLIO Instance HRIDs, barcodes, and serials metadata', new_export_catalog_links_job_path(search_of_druids)],
        ['Import FOLIO Instance HRIDs, barcodes, and serials metadata', new_catalog_record_id_and_barcode_csv_job_path],
        ['Download descriptive metadata as MODS XML', new_download_mods_job_path(search_of_druids)]
      ]],
      ['Manage rights and administrative metadata', [
        ['Update rights', new_rights_job_path(search_of_druids)],
        ['Update licenses and rights statements', new_license_and_rights_statement_job_path(search_of_druids)],
        ['Manage embargo', new_manage_embargo_job_path],
        ['Update governing APO', new_governing_apo_job_path(search_of_druids)],
        ['Apply APO defaults', new_apply_apo_defaults_job_path(search_of_druids)],
        ['Update source id', new_source_id_csv_job_path]
      ]],
      ['Manage structural metadata', [
        ['Update content type', new_content_type_job_path(search_of_druids)],
        ['Export structural metadata', new_export_structural_job_path(search_of_druids)],
        ['Import structural metadata', new_import_structural_job_path],
        ['Update collection', new_collection_job_path(search_of_druids)],
        ['Create virtual object', new_virtual_object_job_path]
      ]],
      ['Tags and Reporting', [
        ['Export tags', new_export_tag_job_path(search_of_druids)],
        ['Import tags', new_import_tag_job_path],
        ['Download tracking sheets', new_tracking_sheet_report_job_path(search_of_druids)],
        ['Download checksum report', new_checksum_report_job_path(search_of_druids)],
        ['Download full Cocina JSON', new_export_cocina_json_job_path(search_of_druids)]
      ]]
    ]
  end
end
