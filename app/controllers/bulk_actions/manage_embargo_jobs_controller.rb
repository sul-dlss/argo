# frozen_string_literal: true

module BulkActions
  class ManageEmbargoJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'ManageEmbargoesJob'

    REQUIRED_HEADERS = %w[druid release_date view download].freeze
    LOCATION_BASED = 'location-based'

    def job_params
      {
        groups: current_user.groups,
        csv_file: CsvUploadNormalizer.read(params[:csv_file].path),
        close_version: params[:close_version]
      }
    end

    def validate_job_params(job_params)
      validate_csv_headers(job_params.fetch(:csv_file), REQUIRED_HEADERS) do |csv|
        missing_location_header_errors(csv)
      end
    end

    private

    # The location header is only required when a row's view or download access is location-based.
    def missing_location_header_errors(csv)
      return [] if csv.headers.include?('location')
      return [] unless csv.any? { |row| [row['view'], row['download']].include?(LOCATION_BASED) }

      ['is missing the location header (required when view or download access is location-based)']
    end
  end
end
