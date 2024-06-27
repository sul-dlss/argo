# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  # @param [Hash<String,Hash>] milestones the milestone data
  # @param [Array<Dor::Services::Client::ObjectVersion::Version>] versions the version tag data
  # @param [Array<Dor::Services::Client::UserVersion::UserVersion>] user_versions the user versions data
  # @param [String] druid the druid of the object
  def initialize(milestones:, versions:, user_versions:, druid:)
    @milestones = milestones
    @versions = versions
    @user_versions = user_versions
    @druid = druid
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

    "#{version} #{val.message}"
  end

  def user_version_for(version)
    user_versions.find { |user_version| user_version.version == version.to_i }&.userVersion
  end

  attr_reader :druid

  private

  attr_reader :milestones, :versions, :user_versions
end
