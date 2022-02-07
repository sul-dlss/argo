# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(presenter:)
    @document = presenter.document
    @cocina = presenter.cocina
    @state_service = presenter.state_service
  end

  def render?
    @cocina.respond_to?(:structural)
  end

  delegate :allows_modification?, to: :@state_service
end
