# frozen_string_literal: true

class VersionMilestonesComponent < ViewComponent::Base
  def initialize(version:, milestones_presenter:, user_versions_presenter:)
    @version = version
    @milestones_presenter = milestones_presenter
    @user_versions_presenter = user_versions_presenter
  end

  def title
    @title ||= milestones_presenter.version_title(version)
  end

  def steps
    @steps ||= milestones_presenter.steps_for(version)
  end

  def link_user_version?
    return false if version.to_i == milestones_presenter.current_version.to_i
    return false if user_version == user_versions_presenter.user_version.to_i

    true
  end

  def link_to_document?
    version.to_i == milestones_presenter.current_version.to_i \
     && user_version == user_versions_presenter.head_user_version&.to_i \
     && user_versions_presenter.user_version.present?
  end

  def user_version_link_or_label
    return link_to(user_version_label, user_version_path) if link_user_version?
    return link_to(user_version_label, solr_document_path(milestones_presenter.druid)) if link_to_document?

    user_version_label
  end

  def user_version
    @user_version ||= user_versions_presenter.user_version_for(version)&.to_i
  end

  def user_version_path
    item_user_version_path(item_id: druid, id: user_version)
  end

  def user_version_label
    "Public version #{user_version}"
  end

  attr_reader :version, :milestones_presenter, :user_versions_presenter

  delegate :druid, to: :milestones_presenter
end
