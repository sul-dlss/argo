# frozen_string_literal: true

# Parse and compare version tags
class VersionTag
  VALID_PATTERN = /(\d+)\.(\d+)\.(\d+)/.freeze

  # @param [String] raw_tag the value of the tag attribute from a Version node
  def self.parse(raw_tag)
    return nil unless raw_tag =~ VALID_PATTERN

    new(
      Regexp.last_match(1),
      Regexp.last_match(2),
      Regexp.last_match(3)
    )
  end

  attr_reader :major, :minor, :admin

  def initialize(maj, min, adm)
    @major = maj.to_i
    @minor = min.to_i
    @admin = adm.to_i
  end
end
