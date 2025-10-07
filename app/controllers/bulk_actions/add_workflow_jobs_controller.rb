# frozen_string_literal: true

module BulkActions
  class AddWorkflowJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'AddWorkflowJob'

    def job_params
      super.merge(workflow: params[:workflow])
    end
  end
end
