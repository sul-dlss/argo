# frozen_string_literal: true

module BulkActions
  class TextExtractionJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'TextExtractionJob'
  end
end
