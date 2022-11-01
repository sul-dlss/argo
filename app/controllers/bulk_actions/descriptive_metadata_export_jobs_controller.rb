# frozen_string_literal: true

module BulkActions
  class DescriptiveMetadataExportJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = "DescriptiveMetadataExportJob"
  end
end
