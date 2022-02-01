# frozen_string_literal: true

class OpenCloseComponent < ApplicationComponent
  # @param [String] id
  def initialize(id:)
    @id = id
  end

  attr_reader :id
end
