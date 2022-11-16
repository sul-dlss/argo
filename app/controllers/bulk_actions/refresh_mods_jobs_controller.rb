# frozen_string_literal: true

module BulkActions
  class RefreshModsJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "RefreshModsJob"
  end
end
