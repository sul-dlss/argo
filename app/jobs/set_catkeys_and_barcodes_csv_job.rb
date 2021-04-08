# frozen_string_literal: true

##
# Job to update/add catkey/barcodes to objects
class SetCatkeysAndBarcodesCsvJob < SetCatkeysAndBarcodesJob
  ##
  # A job that allows a user to specify a list of pids and a list of catkeys to be associated with these pids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file CSV string

  protected

  def params_from(params)
    update_pids = []
    catkeys = nil
    barcodes = nil
    CSV.parse(params[:csv_file], headers: true).each do |row|
      update_pids << row['Druid']
      if row.header?('Catkey')
        catkeys ||= []
        catkeys << row['Catkey'].presence
      end
      if row.header?('Barcode')
        barcodes ||= []
        barcodes << row['Barcode'].presence
      end
    end
    [update_pids, catkeys, barcodes]
  end
end
