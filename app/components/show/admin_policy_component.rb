# frozen_string_literal: true

module Show
  class AdminPolicyComponent < ApplicationComponent
    def initialize(presenter:)
      @presenter = presenter
    end

    attr_reader :presenter

    delegate :document, :cocina, to: :presenter
  end
end
