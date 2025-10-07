# frozen_string_literal: true

module BulkActions
  class ExportCatalogLinksJobsController < ApplicationController
    include CreatesBulkActions

    self.action_type = 'ExportCatalogLinksJob'
  end
end
