# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(cocina:, document:, state_service:)
    @cocina = cocina
    @document = document
    @state_service = state_service
  end

  def render?
    @cocina.respond_to?(:structural)
  end

  delegate :allows_modification?, to: :@state_service
end
