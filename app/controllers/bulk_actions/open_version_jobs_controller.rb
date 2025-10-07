# frozen_string_literal: true

module BulkActions
  class OpenVersionJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'OpenVersionJob'

    def job_params
      super.merge(version_description: params[:version_description])
    end
  end
end
