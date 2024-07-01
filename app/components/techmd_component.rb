# frozen_string_literal: true

class TechmdComponent < ViewComponent::Base
  # @params [String] view_token
  def initialize(view_token:, presenter:)
    @view_token = view_token
    @presenter = presenter
  end

  attr_reader :view_token

  def render?
    !@presenter.user_version_view?
  end
end
