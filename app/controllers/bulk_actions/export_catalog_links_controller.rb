# frozen_string_literal: true

module BulkActions
  class ExportCatalogLinksController < ApplicationController
    include CreatesBulkActions
    self.action_type = 'ExportCatalogLinksJob'
  end
end
