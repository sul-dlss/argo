# frozen_string_literal: true

class ContentsComponent < ApplicationComponent
  def initialize(cocina:, document:)
    @cocina = cocina
    @document = document
  end

  def render?
    @cocina.respond_to?(:structural)
  end
end
