# frozen_string_literal: true

# Presents the event hash in a collapsable format for easier viewing
class EventHashPresenter
  # param [Event] event the event hash to present
  def initialize(event:)
    @event = event
  end

  attr_reader :event

  delegate :data, :event_type, :timestamp, to: :event

  def render
    DeepCompactBlank.run(enumerable: data)
  end

  # Determine if the event has a nested structure.
  #
  # If the event has any values that are arrays or hashes,
  # render the expand/collapse controls. If not, e.g. an
  # event with only string values, do not render the controls
  # because they are noisy and misleading.
  #
  # @return [Boolean] true if there are nested structures, false otherwise
  def render_expand_collapse?
    return false unless data.is_a?(Hash)

    data.values.any?(Enumerable)
  end
end
