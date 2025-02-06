# frozen_string_literal: true

class NewBulkActionButtonComponent < ApplicationComponent
  def link_path
    # Since reset_search does not remove all the bulk action form params from the search state,
    # remove them as specified
    new_bulk_action_path(search_state.reset_search.to_h.except(*bulk_action_params))
  end

  def bulk_action_params
    %i[tag
       who
       what
       workflow
       to
       version_description
       new_apo_id
       download_access
       view_access
       copyright_statement
       copyright_statement_option
       license
       license_option
       use_statement
       use_statement_option
       barcodes
       use_barcodes_option
       catalog_record_ids
       use_catalog_record_ids_option
       current_resource_type
       new_resource_type
       new_content_type
       new_collection_id]
  end
end
