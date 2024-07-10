# frozen_string_literal: true

module Show
  class GovernedByComponent < ApplicationComponent
    def initialize(document:, presenter:)
      @document = document
      @presenter = presenter
    end

    def admin_policy
      return unless @document.apo_id

      helpers.link_to_admin_policy_with_objs(document: @document, value: @document.apo_id)
    end

    def edit?
      !user_version_view? && open_and_not_assembling?
    end

    delegate :version_service, :user_version_view?, to: :@presenter
    delegate :open_and_not_assembling?, to: :version_service
    delegate :id, to: :@document
  end
end
