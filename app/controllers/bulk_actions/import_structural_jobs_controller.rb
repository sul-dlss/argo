# frozen_string_literal: true

module BulkActions
  class ImportStructuralJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'ImportStructuralJob'

    def job_params
      { groups: current_user.groups, csv_file: File.read(params[:csv_file].path) }
    end
  end
end
