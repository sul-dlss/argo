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
        ['Reindex', new_reindex_job_path(search_of_druids)],
        ['Republish objects', new_republish_job_path(search_of_druids)],
        ['Purge', new_purge_job_path(search_of_druids)],
        ['Add workflow', new_add_workflow_job_path(search_of_druids)]
      ]],
      ['Modify objects (via form)', [
        ['Open new object versions', new_open_version_job_path(search_of_druids)],
        ['Close objects', new_close_version_job_path(search_of_druids)],
        ['Update governing APO', new_governing_apo_job_path(search_of_druids)],
        ['Apply APO defaults', new_apply_apo_defaults_job_path(search_of_druids)],
        ['Set object rights', new_rights_job_path(search_of_druids)],
        ['Edit license and rights statements', new_license_and_rights_statement_job_path(search_of_druids)],
        ['Edit catkeys and barcodes', new_catkey_and_barcode_job_path(search_of_druids)],
        ['Refresh MODS from catkey', new_refresh_mods_job_path(search_of_druids)],
        ['Set content type', new_content_type_job_path(search_of_druids)],
        ['Set collection', new_collection_job_path(search_of_druids)]
      ]],
      ['Modify objects (via CSV)', [
        ['Create virtual object(s)', new_virtual_object_job_path],
        ['Edit catkeys and Barcodes from CSV', new_catkey_and_barcode_csv_job_path],
        ['Change source id', new_source_id_csv_job_path],
        ['Export tags to CSV', new_export_tag_job_path(search_of_druids)],
        ['Import tags from CSV', new_import_tag_job_path],
        ['Export structural metadata', new_export_structural_job_path(search_of_druids)],
        ['Import structural metadata', new_import_structural_job_path],
        ['Manage embargo', new_manage_embargo_job_path],
        ['Register druids', new_register_druid_job_path]
      ]],
      ['Generate reports', [
        ['Download checksum report', new_checksum_report_job_path(search_of_druids)],
        ['Download descriptive metadata spreadsheet', new_descriptive_metadata_export_job_path(search_of_druids)],
        ['Upload descriptive metadata spreadsheet', new_descriptive_metadata_import_job_path(search_of_druids)],
        ['Download descriptive metadata (as MODS)', new_download_mods_job_path(search_of_druids)],
        ['Validate Cocina descriptive metadata spreadsheet', new_validate_cocina_descriptive_job_path]
      ]]
    ]
  end
end
