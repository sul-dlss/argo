# frozen_string_literal: true

module BulkActions
  class RightsJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'SetRightsJob'

    def job_params
      super.merge(params.slice(:view_access, :download_access, :controlled_digital_lending,
                               :access_location).to_unsafe_h)
    end
  end
end
