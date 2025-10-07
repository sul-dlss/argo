# frozen_string_literal: true

module BulkActions
  class TextExtractionJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'TextExtractionJob'

    def job_params
      super.merge(text_extraction_languages: params[:text_extraction_languages])
    end
  end
end
