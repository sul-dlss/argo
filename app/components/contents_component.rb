# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(presenter:)
    @item = presenter.item
    @document = presenter.document
    @state_service = presenter.state_service
  end

  def render?
    @item.is_a? Item
  end

  delegate :allows_modification?, to: :@state_service
end
