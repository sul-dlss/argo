# frozen_string_literal: true

class ArgoShowPresenter < Blacklight::ShowPresenter
  class_attribute :thumbnail_presenter
  self.thumbnail_presenter = Blacklight::ThumbnailPresenter

  ##
  # Override the default Blacklight presenter method, to provide citation when
  # rendering the document_heading. Used in show page `render_document_heading`
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L22
  def heading
    CitationPresenter.new(@document).render
  end

  def thumbnail
    @thumbnail ||= thumbnail_presenter.new(document, view_context, view_config)
  end
end
