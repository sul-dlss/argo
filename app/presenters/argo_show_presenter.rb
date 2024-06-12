# frozen_string_literal: true

class ArgoShowPresenter < Blacklight::ShowPresenter
  ##
  # Override the default Blacklight presenter method, to provide citation when
  # rendering the document_heading. Used in show page `render_document_heading`
  # @see https://github.com/projectblacklight/blacklight/blob/c04e80b690bdbd71482d3d91cc168d194d0b6a51/app/presenters/blacklight/document_presenter.rb#L22
  def heading
    CitationPresenter.new(@document).render
  end

  def change_set
    cocina.collection? ? CollectionChangeSet.new(cocina) : ItemChangeSet.new(cocina)
  end

  def id
    cocina.externalIdentifier
  end

  delegate :open?, :openable?, :text_extracting?, :open_and_not_processing?, to: :version_service

  attr_accessor :cocina, :view_token, :state_service, :version_service
end
