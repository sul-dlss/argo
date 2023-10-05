# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  # @param [Hash<String,Hash>] milestones the milestone data
  # @param [Array<Dor::Services::Client::ObjectVersion::Version>] versions the version tag data
  def initialize(milestones:, versions:)
    @milestones = milestones
    @versions = versions
  end

  def each_version(&)
    milestones.keys.sort_by(&:to_i).each(&)
  end

  def steps_for(version)
    @milestones[version]
  end

  def version_title(version)
    val = versions.find { |this| this.versionId == version.to_i }
    return version unless val

    "#{version} (#{val.tag}) #{val.message}"
  end

  private

  attr_reader :milestones, :versions
end
