# frozen_string_literal: true

module BulkActions
  class PrepareJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'PrepareJob'

    def job_params
      super.merge(significance: params[:significance],
                  version_description: params[:version_description])
    end
  end
end
