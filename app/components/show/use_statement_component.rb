# frozen_string_literal: true

module Show
  class UseStatementComponent < ApplicationComponent
    def initialize(change_set:, state_service:)
      @change_set = change_set
      @state_service = state_service
    end

    def use_statement
      @change_set.use_statement || 'Not entered'
    end

    delegate :open?, to: :@state_service
    delegate :id, to: :@change_set
  end
end
