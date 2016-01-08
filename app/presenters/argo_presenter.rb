class ArgoPresenter < Blacklight::DocumentPresenter
  include DorObjectHelper

  ##
  # Override default Blacklight presenter method, to provide citation when
  # rendering the index title label
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L110
  def render_document_index_label(_field, _opts = {})
    render_citation(@document)
  end

  ##
  # Override the default Blacklight presenter method, to provide citation when
  # rendering the document_heading. Used in show page `render_document_heading`
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L22
  def document_heading
    render_citation(@document)
  end
end
