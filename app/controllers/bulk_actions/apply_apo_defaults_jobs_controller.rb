# frozen_string_literal: true

module BulkActions
  class ApplyApoDefaultsJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'ApplyApoDefaultsJob'
  end
end
