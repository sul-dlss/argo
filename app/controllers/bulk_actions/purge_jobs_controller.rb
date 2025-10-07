# frozen_string_literal: true

module BulkActions
  class PurgeJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'PurgeJob'
  end
end
