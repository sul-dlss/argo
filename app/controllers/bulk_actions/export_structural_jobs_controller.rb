# frozen_string_literal: true

module BulkActions
  class ExportStructuralJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "ExportStructuralJob"
  end
end
