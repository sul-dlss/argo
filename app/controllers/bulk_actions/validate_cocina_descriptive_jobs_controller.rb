# frozen_string_literal: true

module BulkActions
  class ValidateCocinaDescriptiveJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'ValidateCocinaDescriptiveJob'

    def job_params
      { csv_file: normalized_csv }
    end

    def normalized_csv
      @normalized_csv ||= CsvUploadNormalizer.read(params[:csv_file].path)
    end
  end
end
