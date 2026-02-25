# frozen_string_literal: true

class CocinaDescriptiveComponent < ApplicationComponent
  def initialize(cocina_display:)
    @cocina_display = cocina_display
  end

  attr_reader :cocina_display

  def cocina_display_methods
    %i[
      title_display_data
      contributor_display_data
      language_display_data
      event_date_display_data
      event_note_display_data
      subject_display_data
      form_display_data
      form_note_display_data
      general_note_display_data
      genre_display_data
      access_display_data
      identifier_display_data
      related_resource_display_data
      map_display_data
    ]
  end
end
