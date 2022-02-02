# frozen_string_literal: true

module Show
  class CatkeyComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    def catkey
      catkey_id || 'None assigned'
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, :catkey_id, to: :@document
  end
end
