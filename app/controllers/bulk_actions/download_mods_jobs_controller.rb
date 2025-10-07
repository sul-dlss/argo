# frozen_string_literal: true

module BulkActions
  class DownloadModsJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'DescmetadataDownloadJob'
  end
end
