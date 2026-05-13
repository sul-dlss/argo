# frozen_string_literal: true

module BulkActions
  class SourceIdCsvJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'SetSourceIdsCsvJob'

    def job_params
      {
        groups: current_user.groups,
        csv_file: CsvUploadNormalizer.read(params[:csv_file].path),
        close_version: params[:close_version]
      }
    end

    def validate_job_params(job_params)
      validate_csv_headers(job_params.fetch(:csv_file), %w[druid source_id])
    end
  end
end
