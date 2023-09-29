# frozen_string_literal: true

module Show
  class TagsComponent < ApplicationComponent
    def initialize(document:)
      @document = document
    end

    def tags
      render_field 'tag_ssim'
    end

    def edit_tags
      link_to edit_item_tags_path(item_id: id),
              aria: { label: 'Edit tags' },
              data: { controller: 'button', action: 'click->button#open' } do
        tag.span class: 'bi-pencil'
      end
    end

    private

    delegate :id, to: :@document
    delegate :blacklight_config, :search_state, :search_action_path, to: :helpers

    def render_field(field_name)
      field_config = fields.fetch(field_name)
      Blacklight::FieldPresenter.new(self, @document, field_config).render
    end

    def fields
      @fields ||= blacklight_config.show_fields_for([:show])
    end
  end
end
