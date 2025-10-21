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

  delegate :open_and_not_assembling?, :version_or_user_version_view?, :user_version_view?, :version_view?,
           :user_version_view, :version_view, to: :@presenter

  delegate :enable_csv?, to: :structural_presenter

  def upload_csv?
    return enable_csv? if !version_or_user_version_view? && open_and_not_assembling?

    false
  end

  def download_csv?
    return enable_csv? unless version_or_user_version_view?

    false
  end

  def structural_link_path
    if user_version_view?
      structure_item_public_version_path(@view_token, user_version_view)
    elsif version_view?
      structure_item_version_path(@view_token, version_view)
    else
      item_structure_path(@view_token)
    end
  end

  def structural_presenter
    @structural_presenter ||= StructuralPresenter.new(@cocina.structural)
  end
end
