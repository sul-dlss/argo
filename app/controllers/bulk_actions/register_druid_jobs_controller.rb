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

    # At least one of these is required: a title, or a catalog record id to derive one from.
    # NOTE: Equivalent validation for the registration page is in CsvRegistrationForm.
    ADDITIONAL_HEADERS = ['title', CatalogRecordId.csv_header].freeze

    def job_params
      { groups: current_user.groups, csv_file: CsvUploadNormalizer.read(params[:csv_file].path) }
    end

    def validate_job_params(job_params)
      validate_csv_headers(job_params.fetch(:csv_file), REQUIRED_HEADERS) do |csv|
        if ADDITIONAL_HEADERS.none? { |header| csv.headers.include?(header) }
          ["missing header. One of these must be provided: #{ADDITIONAL_HEADERS.join(', ')}"]
        elsif csv.any? { |row| ADDITIONAL_HEADERS.none? { |header| row[header].present? } }
          ["missing data. For each row, one of these must be provided: #{ADDITIONAL_HEADERS.join(', ')}"]
        else
          []
        end
      end
    end
  end
end
