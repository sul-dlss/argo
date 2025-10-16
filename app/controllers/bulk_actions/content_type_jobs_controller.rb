# frozen_string_literal: true

module BulkActions
  class ContentTypeJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'SetContentTypeJob'

    def job_params
      super.merge(current_resource_type: params[:current_resource_type],
                  new_content_type: params[:new_content_type],
                  new_resource_type: params[:new_resource_type],
                  viewing_direction: params[:viewing_direction],
                  close_version: params[:close_version])
    end
  end
end
