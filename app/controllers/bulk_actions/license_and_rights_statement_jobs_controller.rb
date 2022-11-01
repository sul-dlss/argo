# frozen_string_literal: true

module BulkActions
  class LicenseAndRightsStatementJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "SetLicenseAndRightsStatementsJob"

    def new
      @license_options = license_options
      super
    end

    def job_params
      super.merge(use_statement_option: params[:use_statement_option],
        use_statement: params[:use_statement],
        copyright_statement_option: params[:copyright_statement_option],
        copyright_statement: params[:copyright_statement],
        license_option: params[:license_option],
        license: params[:license])
    end

    private

    def license_options
      [["-- No license --", ""]] +
        options_for_use_license_type
    end

    def options_for_use_license_type
      # We use `#filter_map` here to remove nils from the options block (for unused deprecated licenses)
      Constants::LICENSE_OPTIONS.filter_map do |attributes|
        next if attributes.key?(:deprecation_warning)

        [attributes.fetch(:label), attributes.fetch(:uri)]
      end
    end
  end
end
