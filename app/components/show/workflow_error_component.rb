# frozen_string_literal: true

module Show
  class WorkflowErrorComponent < ApplicationComponent
    def initialize(document:)
      @document = document
    end

    attr_reader :document

    delegate :blacklight_config, :value_for_wf_error, to: :helpers

    def workflow_errors
      field_config = blacklight_config.show_fields_for([:show]).fetch(SolrDocument::FIELD_WORKFLOW_ERRORS)
      Blacklight::FieldPresenter.new(self, document, field_config).render
    end

    def render?
      document[SolrDocument::FIELD_WORKFLOW_ERRORS]
    end
  end
end
