# frozen_string_literal: true

module Show
  class TicketTagComponent < ApplicationComponent
    def initialize(document:)
      @document = document
    end

    def call
      field_config = fields.fetch(SolrDocument::FIELD_TICKET_TAG)
      Blacklight::FieldPresenter.new(self, @document, field_config).render
    end

    private

    delegate :blacklight_config, :search_state, :search_action_path, to: :helpers

    def fields
      @fields ||= blacklight_config.show_fields_for([:show])
    end
  end
end
