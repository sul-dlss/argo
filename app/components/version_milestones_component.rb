# frozen_string_literal: true

class VersionMilestonesComponent < ViewComponent::Base
  def initialize(version:, milestones_presenter:)
    @version = version
    @milestones_presenter = milestones_presenter
  end

  def title
    @title ||= milestones_presenter.version_title(version)
  end

  def steps
    @steps ||= milestones_presenter.steps_for(version)
  end

  def current_version?
    version.to_i == milestones_presenter.current_version
  end

  def user_version
    @user_version ||= milestones_presenter.user_version_for(version)
  end

  def user_version_path
    item_user_version_path(item_id: druid, id: user_version)
  end

  def user_version_label
    "Public version #{user_version}"
  end

  attr_reader :version, :milestones_presenter

  delegate :druid, to: :milestones_presenter
end
