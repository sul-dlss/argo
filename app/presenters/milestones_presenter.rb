# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  # @param [Hash<String,Hash>] milestones the milestone data
  # @param [Array<Dor::Services::Client::ObjectVersion::Version>] versions the version tag data
  # @param [Array<Dor::Services::Client::UserVersion::UserVersion>] user_versions the user versions data
  def initialize(milestones:, versions:, user_versions:)
    @milestones = milestones
    @versions = versions
    @user_versions = user_versions
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

    "#{version} #{val.message}#{user_version_title_part(version)}"
  end

  private

  attr_reader :milestones, :versions, :user_versions

  def user_version_title_part(version)
    user_version = user_version_for(version)
    return '' unless user_version

    " (User version #{user_version})"
  end

  def user_version_for(version)
    user_versions.find { |user_version| user_version.version == version.to_i }&.userVersion
  end
end
