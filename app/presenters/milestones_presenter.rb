# frozen_string_literal: true

# Displays milestones for each of the versions for an object
class MilestonesPresenter
  def initialize(milestones:, versions:)
    @milestones = milestones
    @versions = versions
  end

  def each_version
    milestones.keys.sort_by(&:to_i)
  end

  def steps_for(version)
    @milestones[version].each_with_index { |(key, milestone), index| yield(key, milestone, index) }
  end

  def version_title(version)
    version_hash[version] ? "#{version} (#{version_hash[version][:tag]}) #{version_hash[version][:desc]}" : version
  end

  private

  attr_reader :milestones, :versions

  def version_hash
    @version_hash ||= versions&.each_with_object({}) do |rec, obj|
      (version, tag, desc) = rec.split(';')
      obj[version] = {
        tag: tag,
        desc: desc
      }
    end
  end
end
