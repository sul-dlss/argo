# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(presenter:)
    @item = presenter.item
    @document = presenter.document
    @state_service = presenter.state_service
    @view_token = presenter.view_token
  end

  def render?
    @item.is_a? Item
  end

  def number_of_file_sets
    @item.file_sets.size
  end

  delegate :allows_modification?, to: :@state_service
end
