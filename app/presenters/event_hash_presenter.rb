# frozen_string_literal: true

# Presents the event hash in a collapsable format for easier viewing
class EventHashPresenter
  def initialize(event:)
    @event = event
  end

  def render
    DeepCompactBlank.run(enumerable: @event)
  end
end
