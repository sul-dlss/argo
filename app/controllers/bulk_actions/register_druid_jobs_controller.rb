# frozen_string_literal: true

module BulkActions
  class RegisterDruidJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'RegisterDruidsJob'

    def job_params
      { groups: current_user.groups, csv_file: CsvUploadNormalizer.read(params[:csv_file].path) }
    end
  end
end
