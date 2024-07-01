# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(presenter:)
    @document = presenter.document
    @cocina = presenter.cocina
    @presenter = presenter
    @view_token = presenter.view_token
  end

  def render?
    @cocina.respond_to?(:structural)
  end

  delegate :open_and_not_assembling?, :user_version_view?, to: :@presenter

  def upload_csv?
    !user_version_view? && open_and_not_assembling?
  end

  def download_csv?
    !user_version_view?
  end
end
