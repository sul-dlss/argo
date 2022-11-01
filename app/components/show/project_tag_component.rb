# frozen_string_literal: true

module Show
  class ProjectTagComponent < ApplicationComponent
    def initialize(document:)
      @document = document
    end

    def call
      render_field "project_tag_ssim"
    end

    private

    delegate :blacklight_config, :search_state, :search_action_path, to: :helpers

    def render_field(field_name)
      field_config = fields.fetch(field_name)
      Blacklight::FieldPresenter.new(self, @document, field_config).render
    end

    def fields
      @fields ||= blacklight_config.show_fields_for(:show)
    end
  end
end
