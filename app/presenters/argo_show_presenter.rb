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

  def user_version_view?
    user_versions_presenter.present? && user_version.present?
  end

  def head_user_version_view?
    user_version_view? && user_version == head_user_version
  end

  delegate :open?, :openable?, :open_and_not_assembling?, to: :version_service

  delegate :user_version, :head_user_version, to: :user_versions_presenter

  attr_accessor :cocina, :view_token, :state_service, :version_service, :user_versions_presenter
end
