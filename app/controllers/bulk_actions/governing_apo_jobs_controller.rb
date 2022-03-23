# frozen_string_literal: true

module BulkActions
  class GoverningApoJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'SetGoverningApoJob'

    def job_params
      super.merge(new_apo_id: params[:new_apo_id])
    end
  end
end
