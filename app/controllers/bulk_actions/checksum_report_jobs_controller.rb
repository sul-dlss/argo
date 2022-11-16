# frozen_string_literal: true

module BulkActions
  class ChecksumReportJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "ChecksumReportJob"
  end
end
