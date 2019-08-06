# frozen_string_literal: true

class ArgoIndexPresenter < Blacklight::IndexPresenter
  include DorObjectHelper

  ##
  # Override default Blacklight presenter method, to provide citation when
  # rendering the document's title on the index page.
  # @see https://github.com/projectblacklight/blacklight/blob/15eb3fcb5444cbf835fc21f26aac2139110eeef8/app/presenters/blacklight/document_presenter.rb#L38
  def heading
    render_citation(@document)
  end
end
