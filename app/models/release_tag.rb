# frozen_string_literal: true

class ReleaseTag
  attr_reader :to, :what, :when, :who, :release

  ##
  # @param [String] to 'SearchWorks'
  # @param [String] what 'self', 'collection'
  # @param [String] when_time Note: we use "when" in other places for this. And "when"
  # is how it is stored in the xml, but "when" is a reserved word in Ruby
  # @param [String] who 'esnowden'
  # @param [String, Boolean] release 'true', false
  def initialize(to:, what:, when_time:, who:, release:)
    @to = to
    @what = what
    @when = when_time
    @who = who
    @release = string_to_boolean(release)
  end

  ##
  # Converts an XML element into a ReleaseTag object
  # @param [Nokogiri::XML::Element] tag created from a Release tag parsed by Nokogiri
  # @return [ReleaseTag]
  def self.from_tag(tag)
    attributes = tag.attributes
    new(
      to: attributes['to'].value,
      what: attributes['what'].value,
      when_time: attributes['when'].value,
      who: attributes['who'].value,
      release: tag.text
    )
  end

  private

  def string_to_boolean(string)
    case string
    when 'true'
      true
    when 'false'
      false
    else
      string
    end
  end
end
