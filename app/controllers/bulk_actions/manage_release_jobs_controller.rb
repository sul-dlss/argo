# frozen_string_literal: true

module BulkActions
  class ManageReleaseJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'ReleaseObjectJob'

    def job_params
      super.merge(to: params[:to], who: params[:who], what: params[:what], tag: params[:tag])
    end
  end
end
