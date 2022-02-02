# frozen_string_literal: true

module Show
  class BarcodeComponent < ApplicationComponent
    def initialize(change_set:)
      @change_set = change_set
    end

    def barcode
      @change_set.barcode || 'Not recorded'
    end

    delegate :id, to: :@change_set
  end
end
