# frozen_string_literal: true

module BulkActions
  class SourceIdCsvJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'SetSourceIdsCsvJob'

    def job_params
      { groups: current_user.groups, csv_file: File.read(params[:csv_file].path) }
    end
  end
end
