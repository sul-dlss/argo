# frozen_string_literal: true

module BulkActions
  class ApplyApoDefaultsJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'ApplyApoDefaultsJob'

    def job_params
      super.merge(close_version: params[:close_version])
    end
  end
end
