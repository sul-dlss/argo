# frozen_string_literal: true

class SidebarComponent < Blacklight::Search::SidebarComponent
  def initialize(response:, **kwargs)
    @response = response
    super
  end

  delegate :has_search_parameters?, to: :helpers

  def root_path(args = {})
    helpers.root_path(args)
  end
end
