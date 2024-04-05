# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(presenter:)
    @document = presenter.document
    @cocina = presenter.cocina
    @state_service = presenter.state_service
    @view_token = presenter.view_token
  end

  def render?
    @cocina.respond_to?(:structural)
  end

  delegate :open?, to: :@state_service
end
