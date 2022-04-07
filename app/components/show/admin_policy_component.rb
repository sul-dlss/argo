# frozen_string_literal: true

module Show
  class AdminPolicyComponent < ApplicationComponent
    def initialize(presenter:)
      @presenter = presenter
    end

    attr_reader :presenter

    delegate :document, :item, :view_token, to: :presenter
  end
end
