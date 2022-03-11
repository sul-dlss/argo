# frozen_string_literal: true

module BulkActions
  class DescriptiveDownloadJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'DescmetadataDownloadJob'
  end
end
