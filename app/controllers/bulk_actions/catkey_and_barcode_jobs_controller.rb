# frozen_string_literal: true

module BulkActions
  class CatkeyAndBarcodeJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "SetCatkeysAndBarcodesJob"

    def job_params
      super.merge(use_catkeys_option: params[:use_catkeys_option],
        catkeys: params[:catkeys],
        use_barcodes_option: params[:use_barcodes_option],
        barcodes: params[:barcodes])
    end
  end
end
