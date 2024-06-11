# frozen_string_literal: true

module Show
  class UseStatementComponent < ApplicationComponent
    def initialize(change_set:, version_service:)
      @change_set = change_set
      @version_service = version_service
    end

    def use_statement
      @change_set.use_statement || 'Not entered'
    end

    delegate :open_and_not_assembling?, to: :@version_service
    delegate :id, to: :@change_set
  end
end
