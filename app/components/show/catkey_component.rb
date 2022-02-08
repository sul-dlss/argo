# frozen_string_literal: true

module Show
  class CatkeyComponent < ApplicationComponent
    def initialize(change_set:, state_service:)
      @change_set = change_set
      @state_service = state_service
    end

    def catkey
      @change_set.catkey.presence || 'None assigned'
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, to: :@change_set
  end
end
