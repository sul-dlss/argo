# frozen_string_literal: true

class Search::SidebarComponent < Blacklight::Component
  def initialize(blacklight_config:, response:, view_config:)
    @blacklight_config = blacklight_config
    @response = response
    @view_config = view_config
  end

  attr_reader :blacklight_config, :response, :view_config
end
