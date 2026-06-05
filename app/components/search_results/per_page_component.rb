# frozen_string_literal: true

module SearchResults
  class PerPageComponent < Blacklight::Search::PerPageComponent
    def dropdown_class
      SearchResults::DropdownComponent
    end
  end
end
