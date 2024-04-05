# frozen_string_literal: true

module Show
  class CatalogRecordIdComponent < ApplicationComponent
    def initialize(change_set:, state_service:)
      @change_set = change_set
      @state_service = state_service
    end

    def catalog_record_id
      @change_set.catalog_record_ids.presence&.join(', ') || 'None assigned'
    end

    delegate :open?, to: :@state_service
    delegate :id, to: :@change_set
    delegate :manage_label, to: CatalogRecordId
  end
end
