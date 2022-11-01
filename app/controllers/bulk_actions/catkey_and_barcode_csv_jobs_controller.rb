# frozen_string_literal: true

module BulkActions
  class CatkeyAndBarcodeCsvJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "SetCatkeysAndBarcodesCsvJob"

    def job_params
      {groups: current_user.groups, csv_file: CsvUploadNormalizer.read(params[:csv_file].path)}
    end

    def validate_job_params(job_params)
      validate_csv_headers(job_params.fetch(:csv_file), ["Druid"])
    end
  end
end
