# frozen_string_literal: true

# Parses rights XML to produce a label
class RightsLabeler
  # @param [Cocina::Models::AdminPolicyDefaultAccess] default_access admin policy default access instance
  # @return [String] a label expressing the rights of the object
  def self.label(default_access)
    new(default_access).label
  end

  # @param [Cocina::Models::AdminPolicyDefaultAccess] default_access admin policy default access instance
  def initialize(default_access)
    @default_access = default_access
  end

  # @return [String] a label expressing the rights of the object
  def label
    return '' if default_access.nil? || default_access.access.nil?

    if default_access&.controlledDigitalLending
      'cdl-stanford-nd'
    elsif default_access&.access == 'stanford'
      default_access&.download == 'none' ? 'stanford-nd' : 'stanford'
    elsif default_access&.access == 'world'
      default_access&.download == 'none' ? 'world-nd' : 'world'
    elsif default_access&.access == 'location-based' && default_access&.readLocation&.present?
      "loc:#{default_access.readLocation}"
    else # this covers both citation-only and dark
      default_access.access
    end
  end

  private

  attr_reader :default_access
end
