# frozen_string_literal: true

module BulkActions
  class ExportCocinaJsonJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "ExportCocinaJsonJob"
  end
end
