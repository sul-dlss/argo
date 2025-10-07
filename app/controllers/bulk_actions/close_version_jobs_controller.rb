# frozen_string_literal: true

module BulkActions
  class CloseVersionJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'CloseVersionJob'
  end
end
