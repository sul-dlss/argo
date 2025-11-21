# frozen_string_literal: true

module BulkActions
  class DoiAssignmentJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'DoiAssignmentJob'

    def job_params
      super.merge(close_version: params[:close_version])
    end

    def validate_job_params(job_params)
      return Success() if job_params[:druids].size <= Settings.datacite.batch_size

      Failure(["Maximum number of druids is #{helpers.number_with_delimiter(Settings.datacite.batch_size)}"])
    end
  end
end
