# frozen_string_literal: true

module BulkActions
  class RightsJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'SetRightsJob'

    def job_params
      super.merge(rights: params[:rights])
    end
  end
end
