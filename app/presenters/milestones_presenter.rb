# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  # @param [String] druid the druid of the object
  # @param [Array<Dor::Services::Client::Version::Version>] version_inventory the version inventory
  def initialize(druid:, version_inventory:)
    @druid = druid
    @version_inventory = version_inventory
  end

  def each_version(&)
    milestones.keys.sort_by(&:to_i).each(&)
  end

  def steps_for(version)
    milestones[version.to_s]
  end

  def version_title(version)
    val = version_inventory.find { |this| this.versionId == version.to_i }
    return version unless val

    "#{version} #{val.message}"
  end

  private

  attr_reader :druid, :version_inventory

  def milestones
    @milestones ||= MilestoneService.milestones_for(druid:)
  end
end
