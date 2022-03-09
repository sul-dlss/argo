# frozen_string_literal: true

# Parses rights XML to produce a label
class RightsLabeler
  # @param [Cocina::Models::AdminPolicyAccessTemplate] default_access admin policy default access instance
  # @return [String] a label expressing the rights of the object
  def self.label(default_access)
    new(default_access).label
  end

  # @param [Cocina::Models::AdminPolicyAccessTemplate] default_access admin policy default access instance
  def initialize(default_access)
    @default_access = default_access
  end

  # @return [String] a label expressing the rights of the object
  def label
    return '' unless default_access&.view

    if default_access.controlledDigitalLending
      'cdl-stanford-nd'
    elsif default_access.view == 'stanford'
      default_access.download == 'none' ? 'stanford-nd' : 'stanford'
    elsif default_access.view == 'world'
      default_access.download == 'none' ? 'world-nd' : 'world'
    elsif default_access.view == 'location-based' && default_access.location.present?
      "loc:#{default_access.location}"
    else # this covers both citation-only and dark
      default_access.view
    end
  end

  private

  attr_reader :default_access
end
