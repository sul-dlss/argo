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
        label_header_errors(csv) + missing_title_errors(csv)
      end
    end

    private

    def label_header_errors(csv)
      # "label" has been removed from Cocina but users may still have template files referencing it.
      return [] if csv.headers.none? { |header| header&.casecmp?('label') }

      ['has a "label" column, which is not valid. Titles must be in a column named "title".']
    end

    # A missing column reads as blank data for every row, so this covers an absent header too.
    def missing_title_errors(csv)
      return [] if csv.all? { |row| ADDITIONAL_HEADERS.any? { |header| row[header].present? } }

      ["missing title. For each row, one of these must be provided: #{ADDITIONAL_HEADERS.join(', ')}"]
    end
  end
end
