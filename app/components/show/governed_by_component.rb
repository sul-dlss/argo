# frozen_string_literal: true

module Show
  class GovernedByComponent < ApplicationComponent
    def initialize(document:, version_service:)
      @document = document
      @version_service = version_service
    end

    def admin_policy
      return unless @document.apo_id

      helpers.link_to_admin_policy_with_objs(document: @document, value: @document.apo_id)
    end

    delegate :open?, to: :@version_service
    delegate :id, to: :@document
  end
end
