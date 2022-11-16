# frozen_string_literal: true

module BulkActions
  class ReindexJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "RemoteIndexingJob"
  end
end
