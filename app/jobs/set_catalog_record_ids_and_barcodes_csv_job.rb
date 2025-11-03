# frozen_string_literal: true

##
# Job to update/add catalog record IDs/barcodes to objects
class SetCatalogRecordIdsAndBarcodesCsvJob < BulkActionCsvJob
  class SetCatalogRecordIdsAndBarcodesCsvJobItem < BulkActionCsvJobItem
    attr_reader :change_set

    def perform
      return unless check_update_ability?

      @change_set = build_change_set
      return failure!(message: "Invalid #{CatalogRecordId.label}/barcode: #{change_set.errors.full_messages.to_sentence}") unless change_set.validate(change_set_params)
      return failure!(message: 'No changes specified for object') unless change_set.changed?

      open_new_version_if_needed!(description: 'Updated FOLIO HRID, barcode, or serials metadata')

      log_catalog_record_id_update
      log_barcode_update

      @change_set = build_change_set # With the new cocina model
      change_set.validate(change_set_params)
      change_set.save
      close_version_if_needed!

      success!(message: "#{CatalogRecordId.label}/barcode added/updated/removed successfully")
    end

    def build_change_set
      change_set_class = cocina_object.dro? ? ItemChangeSet : CollectionChangeSet
      change_set_class.new(cocina_object)
    end

    def change_set_params
      @change_set_params ||= {}.tap do |change_set_params|
        change_set_params[:barcode] = row['barcode'] if row.header?('barcode') && cocina_object.dro?

        if row.header?(CatalogRecordId.csv_header)
          change_set_params[:catalog_record_ids] = begin
            catalog_record_id_column_indices = row.headers.each_index.select { |index| row.headers[index] == CatalogRecordId.csv_header }
            row.fields(*catalog_record_id_column_indices).compact
          end

          change_set_params[:refresh] = row['refresh']&.downcase != 'false'
          change_set_params[:part_label] = row['part_label']&.strip
          change_set_params[:sort_key] = row['sort_key']&.strip
        end
      end
    end

    def log_catalog_record_id_update
      return unless change_set.changed?(:catalog_record_ids)

      if change_set.catalog_record_ids.present?
        log("Adding #{CatalogRecordId.label} of #{change_set.catalog_record_ids.join(', ')}")
      else
        log("Removing #{CatalogRecordId.label}")
      end
    end

    def log_barcode_update
      # ItemChangeSets have a barcode; CollectionChangeSets do not.
      return unless change_set.is_a?(ItemChangeSet) && change_set.changed?(:barcode)

      if change_set.barcode
        log("Adding barcode of #{change_set.barcode}")
      else
        log('Removing barcode')
      end
    end
  end
end
