# frozen_string_literal: true

module Show
  class BarcodeComponent < ApplicationComponent
    def initialize(change_set:, version_service:)
      @change_set = change_set
      @version_service = version_service
    end

    def barcode
      @change_set.barcode || 'Not recorded'
    end

    delegate :open?, to: :@version_service
    delegate :id, to: :@change_set
  end
end
