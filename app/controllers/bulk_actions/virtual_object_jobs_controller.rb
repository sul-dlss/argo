# frozen_string_literal: true

module BulkActions
  class VirtualObjectJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'CreateVirtualObjectsJob'

    def job_params
      { groups: current_user.groups, csv_file: CsvUploadNormalizer.read(params[:csv_file].path) }
    end
  end
end
