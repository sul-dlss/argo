# frozen_string_literal: true

module Show
  class AgreementComponent < ApplicationComponent
    def initialize(presenter:)
      @presenter = presenter
    end

    attr_reader :presenter

    delegate :document, :cocina, :view_token, to: :presenter
    delegate :state_service, to: :@presenter
  end
end
