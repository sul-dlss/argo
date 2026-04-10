# frozen_string_literal: true

module BulkActions
  class MissingTechmdReportJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'MissingTechmdReportJob'
  end
end
