# frozen_string_literal: true

module BulkActions
  class ValidateCocinaDescriptiveJobsController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'ValidateCocinaDescriptiveJob'
  end
end
