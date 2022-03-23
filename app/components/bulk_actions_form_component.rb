# frozen_string_literal: true

class BulkActionsFormComponent < ApplicationComponent
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
        ['Manage release', new_manage_release_job_path],
        ['Reindex', new_reindex_job_path],
        ['Republish objects', new_republish_job_path],
        ['Purge', new_purge_job_path],
        ['Add workflow', new_add_workflow_job_path]
      ]],
      ['Modify objects (via form)', [
        ['Open new object versions', new_prepare_job_path],
        ['Close objects', new_close_version_job_path],
        ['Update governing APO', new_governing_apo_job_path],
        ['Apply APO defaults', new_apply_apo_defaults_job_path],
        ['Set object rights', new_rights_job_path],
        ['Edit license and rights statements', new_license_and_rights_statement_job_path],
        ['Edit catkeys and barcodes', new_catkey_and_barcode_job_path],
        ['Refresh MODS from catkey', new_refresh_mods_job_path],
        ['Set content type', new_content_type_job_path],
        ['Set collection', new_collection_job_path]
      ]],
      ['Modify objects (via CSV)', [
        ['Create virtual object(s)', new_virtual_object_job_path],
        ['Edit catkeys and Barcodes from CSV', new_catkey_and_barcode_csv_job_path],
        ['Change source id', new_source_id_csv_job_path],
        ['Export tags to CSV', new_export_tag_job_path],
        ['Import tags from CSV', new_import_tag_job_path],
        ['Export structural metadata', new_export_structural_job_path],
        ['Manage embargo', new_manage_embargo_job_path],
        ['Register druids', new_register_druid_job_path]
      ]],
      ['Generate reports', [
        ['Download checksum report', new_checksum_report_job_path],
        ['Download descriptive metadata (as MODS)', new_descriptive_download_job_path]
      ]]
    ]
  end
end
