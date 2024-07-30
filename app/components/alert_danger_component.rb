# frozen_string_literal: true

class AlertDangerComponent < ApplicationComponent
  def initialize(text:)
    @text = text
  end
end
