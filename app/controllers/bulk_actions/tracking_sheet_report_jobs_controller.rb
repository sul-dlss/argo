# frozen_string_literal: true

module BulkActions
  class TrackingSheetReportJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'TrackingSheetReportJob'
  end
end
