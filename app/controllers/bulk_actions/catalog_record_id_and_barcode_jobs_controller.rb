# frozen_string_literal: true

module BulkActions
  class CatalogRecordIdAndBarcodeJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "SetCatalogRecordIdsAndBarcodesJob"

    def job_params
      super.merge(use_catalog_record_ids_option: params[:use_catalog_record_ids_option],
        catalog_record_ids: params[:catalog_record_ids],
        use_barcodes_option: params[:use_barcodes_option],
        barcodes: params[:barcodes])
    end
  end
end
