# frozen_string_literal: true

module BulkActions
  class RefreshDescriptiveMetadataJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'RefreshDescriptiveMetadataJob'

    def job_params
      super.merge(close_version: params[:close_version])
    end
  end
end
