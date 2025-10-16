# frozen_string_literal: true

module BulkActions
  class GoverningApoJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'SetGoverningApoJob'

    def new
      @apo_list = AdminPolicyOptions.for(current_user)
      super
    end

    def job_params
      super.merge(new_apo_id: params[:new_apo_id], close_version: params[:close_version])
    end
  end
end
