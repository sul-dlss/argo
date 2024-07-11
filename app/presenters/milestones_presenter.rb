# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  # @param [String] druid the druid of the object
  def initialize(druid:)
    @druid = druid
  end

  def each_version(&)
    milestones.keys.sort_by(&:to_i).each(&)
  end

  def steps_for(version)
    milestones[version]
  end

  def version_title(version)
    val = versions.find { |this| this.versionId == version.to_i }
    return version unless val

    "#{version} #{val.message}"
  end

  def user_version_for(version)
    user_versions.find { |user_version| user_version.version == version.to_i }&.userVersion
  end

  def valid_user_version?(user_version)
    user_version.nil? || user_versions.any? { |version| version.userVersion.to_s == user_version }
  end

  def head_user_version
    @head_user_version ||= user_versions.max { |user_version1, user_version2| user_version1.userVersion.to_i <=> user_version2.userVersion.to_i }&.userVersion.to_s
  end

  def current_version
    @current_version ||= versions.max_by(&:versionId)&.versionId
  end

  attr_reader :druid

  private

  def milestones
    @milestones ||= MilestoneService.milestones_for(druid:)
  end

  def versions
    @versions ||= object_client.version.inventory
  end

  def user_versions
    @user_versions ||= object_client.user_version.inventory
  end

  def object_client
    @object_client ||= Dor::Services::Client.object(druid)
  end
end
