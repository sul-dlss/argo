# frozen_string_literal: true

module Show
  class GovernedByComponent < ApplicationComponent
    def initialize(document:, state_service:)
      @document = document
      @state_service = state_service
    end

    def admin_policy
      return unless @document.apo_id

      helpers.link_to_admin_policy_with_objs(document: @document, value: @document.apo_id)
    end

    delegate :allows_modification?, to: :@state_service
    delegate :id, to: :@document
  end
end
