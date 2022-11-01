# frozen_string_literal: true

module BulkActions
  class ExportTagJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "ExportTagsJob"
  end
end
