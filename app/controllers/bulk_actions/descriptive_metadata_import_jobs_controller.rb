# frozen_string_literal: true

module BulkActions
  class DescriptiveMetadataImportJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'DescriptiveMetadataImportJob'

    def job_params
      {
        groups: current_user.groups,
        csv_file: CsvUploadNormalizer.read(params[:csv_file].path, remove_columns_without_headers: true, remove_preamble_rows: true),
        csv_filename: params[:csv_file].original_filename
      }
    end

    def validate_job_params(job_params)
      csv = CSV.parse(job_params.fetch(:csv_file), headers: true)
      validator = DescriptionValidator.new(csv, bulk_job: true)
      validator.valid? ? Success() : Failure(validator.errors)
    end
  end
end
