class ArgoPresenter < Blacklight::DocumentPresenter
  include DorObjectHelper

  ##
  # Override default Blacklight presenter method, to provide citation when
  # rendering the index title label. Because of some strangeness with the
  # #render_thumbnail_tag method from Blacklight, we need to check if its not
  # the default id and if so call super.
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L110
  def render_document_index_label(field, _opts = {})
    if field != @document.id
      super
    else
      render_citation(@document)
    end
  end

  ##
  # Override the default Blacklight presenter method, to provide citation when
  # rendering the document_heading. Used in show page `render_document_heading`
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L22
  def document_heading
    render_citation(@document)
  end
end
