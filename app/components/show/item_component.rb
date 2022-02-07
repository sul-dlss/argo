# frozen_string_literal: true

module Show
  class ItemComponent < ApplicationComponent
    def initialize(presenter:)
      @presenter = presenter
    end

    attr_reader :presenter

    delegate :document, :cocina, :techmd, to: :presenter
    delegate :state_service, to: :@presenter
  end
end
