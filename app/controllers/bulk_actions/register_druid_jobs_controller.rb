# frozen_string_literal: true

module BulkActions
  class RegisterDruidJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'RegisterDruidsJob'

    REQUIRED_HEADERS = %w[
      content_type
      administrative_policy_object
      source_id
      initial_workflow
      rights_view
      rights_download
    ].freeze

    def job_params
      { groups: current_user.groups, csv_file: CsvUploadNormalizer.read(params[:csv_file].path) }
    end

    def validate_job_params(job_params)
      validate_csv_headers(job_params.fetch(:csv_file), REQUIRED_HEADERS)
    end
  end
end
