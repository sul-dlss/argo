# frozen_string_literal: true

class DetailsComponent < ApplicationComponent
  def initialize(solr_document:)
    @solr_document = solr_document
  end

  def project_tag
    render_field 'project_tag_ssim'
  end

  def tags
    render_field('tag_ssim')
  end

  delegate :object_type, :content_type, :source_id, :created_date,
           :released_to, :preservation_size, :catkey_id, :barcode, to: :@solr_document

  delegate :blacklight_config, :search_state, :search_action_path, to: :helpers

  private

  def render_field(field_name)
    field_config = fields.fetch(field_name)
    Blacklight::FieldPresenter.new(self, @solr_document, field_config).render
  end

  def fields
    @fields ||= blacklight_config.show_fields_for(:show)
  end
end
