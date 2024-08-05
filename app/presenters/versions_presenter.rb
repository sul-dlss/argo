# frozen_string_literal: true

# Displays versions for an object
class VersionsPresenter
  # @param [String] version_view the version of the object to display
  # @param [Array<Dor::Services::Client::Version::Version>] version_inventory the version inventory
  def initialize(version_view:, version_inventory:)
    @version_view = version_view&.to_i
    @version_inventory = version_inventory
  end

  def current_version
    @current_version ||= version_inventory.max_by(&:versionId)&.versionId&.to_i
  end

  def cocina?(version)
    version_inventory.find { |this| this.versionId == version.to_i }&.cocina? || false
  end

  attr_reader :version_inventory, :version_view
end
