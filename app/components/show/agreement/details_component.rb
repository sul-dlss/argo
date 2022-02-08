# frozen_string_literal: true

module Show
  module Agreement
    class DetailsComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
        @solr_document = presenter.document
      end

      def project_tag
        render_field 'project_tag_ssim'
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

      delegate :id, :object_type, :created_date, :preservation_size, to: :@solr_document
      delegate :state_service, to: :@presenter

      delegate :blacklight_config, :search_state, :search_action_path, to: :helpers

      def released_to
        @solr_document.released_to.presence&.to_sentence || 'Not released'
      end

      private

      def render_field(field_name)
        field_config = fields.fetch(field_name)
        Blacklight::FieldPresenter.new(self, @solr_document, field_config).render
      end

      def fields
        @fields ||= blacklight_config.show_fields_for(:show)
      end
    end
  end
end
