# frozen_string_literal: true

module BulkActions
  class RepublishJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'RepublishJob'
  end
end
