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

  # Determine if the data has nested structures that can be expanded/collapsed
  #
  # If the data structure isn't an expandable hash, return false
  # Otherwise, check if any value is a hash or an array containing hashes/arrays.
  #
  # @return [Boolean] true if there are nested structures, false otherwise
  def render_expand_collapse?
    return false unless data.is_a?(Hash)

    data.any? do |v|
      v.is_a?(Hash) || (v.is_a?(Array) && (v.any?(Hash) || v.any?(Array)))
    end
  end
end
