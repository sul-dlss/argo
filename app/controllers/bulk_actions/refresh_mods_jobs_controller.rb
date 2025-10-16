# frozen_string_literal: true

module BulkActions
  class RefreshModsJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'RefreshModsJob'

    def job_params
      super.merge(close_version: params[:close_version])
    end
  end
end
