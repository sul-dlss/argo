# frozen_string_literal: true

module BulkActions
  class DescriptiveMetadataImportJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'DescriptiveMetadataImportJob'

    def create
      csv = CSV.parse(normalized_csv, headers: true)
      validator = DescriptionValidator.new(csv, bulk_job: true)
      if validator.valid?
        super
      else
        @errors = validator.errors
        render :new, status: :unprocessable_entity
      end
    end

    def job_params
      { groups: current_user.groups, csv_file: normalized_csv }
    end

    def normalized_csv
      @normalized_csv ||= CsvUploadNormalizer.read(params[:csv_file].path)
    end
  end
end
