# frozen_string_literal: true

##
# Job to update/add catalog record IDs/barcodes to objects
class SetCatalogRecordIdsAndBarcodesCsvJob < SetCatalogRecordIdsAndBarcodesJob
  ##
  # A job that allows a user to specify a list of druids and a list of catalog record IDs to be associated with these druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file CSV string

  private

  def params_from(params)
    update_druids = []
    catalog_record_ids = nil
    barcodes = nil
    refresh = nil
    CSV.parse(params[:csv_file], headers: true).each do |row|
      update_druids << row['Druid']
      if row.header?(CatalogRecordId.label)
        catalog_record_ids ||= []
        refresh ||= []
        catalog_record_ids << catalog_record_id_cols(row)
        refresh << refresh?(row)
      end
      if row.header?('Barcode')
        barcodes ||= []
        barcodes << row['Barcode'].presence
      end
    end
    [update_druids, catalog_record_ids, barcodes, refresh]
  end

  def refresh?(row)
    (row['Refresh']&.downcase != 'false')
  end

  def catalog_record_id_cols(row)
    catalog_record_id_cols = row.headers.flat_map.with_index do |header, index|
      index if header == CatalogRecordId.label
    end.compact
    row.values_at(*catalog_record_id_cols).compact
  end
end
