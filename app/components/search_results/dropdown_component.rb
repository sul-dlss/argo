# frozen_string_literal: true

module SearchResults
  class DropdownComponent < Blacklight::System::DropdownComponent
    def before_render
      with_button(label: button_label, classes: %w[btn btn-outline-primary dropdown-toggle]) unless button
      super
    end
  end
end
