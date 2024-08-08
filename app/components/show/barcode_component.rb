# frozen_string_literal: true

module Show
  class BarcodeComponent < ApplicationComponent
    def initialize(presenter:)
      @presenter = presenter
    end

    def barcode
      change_set.barcode || 'Not recorded'
    end

    def edit?
      !version_or_user_version_view? && open_and_not_assembling?
    end

    delegate :version_service, :version_or_user_version_view?, :change_set, to: :@presenter
    delegate :open_and_not_assembling?, to: :version_service
    delegate :id, to: :change_set
  end
end
