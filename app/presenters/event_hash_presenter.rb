# frozen_string_literal: true

# Presents the event hash in a collapsable format for easier viewing
class EventHashPresenter
  # param [Event] event the event hash to present
  def initialize(event:)
    @event_data = event.data
  end

  def render
    DeepCompactBlank.run(enumerable: @event_data)
  end
end
