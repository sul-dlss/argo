# frozen_string_literal: true

class VersionMilestonesComponent < ViewComponent::Base
  # version = version for the milestone to be rendered
  # user_version = user version for the milestone to be rendered (nil if there is no user version for the version)
  # current_version = current (latest) version of the object
  # version_view = version of the object to be displayed for the page (nil if this isn't a version page view)
  # user_version_view = user version of the object to be displayed for the page (nil if this isn't a user version page view)

  def initialize(druid:, version:, user_versions_presenter:, versions_presenter:, milestones_presenter:)
    @druid = druid
    @version = version.to_i
    @milestones_presenter = milestones_presenter
    @user_versions_presenter = user_versions_presenter
    @versions_presenter = versions_presenter
  end

  def title
    @title ||= milestones_presenter.version_title(version)
  end

  def steps
    @steps ||= milestones_presenter.steps_for(version) || {}
  end

  def link_version?
    return false unless cocina_for_version?
    return false if version == current_version
    return false if version == version_view

    true
  end

  def version_link_or_label
    return link_to(title, version_path) if link_version?
    return link_to(title, solr_document_path(druid)) if version_link_to_document?

    title
  end

  def link_user_version?
    return false if version == current_version
    return false if user_version == user_version_view

    true
  end

  def version_link_to_document?
    version_view && version == current_version && version != version_view
  end

  def user_version_link_to_document?
    version == current_version \
     && user_version == head_user_version \
     && user_version_view.present?
  end

  def user_version_link_or_label
    return link_to(user_version_label, user_version_path) if link_user_version?
    return link_to(user_version_label, solr_document_path(druid)) if user_version_link_to_document?

    user_version_label
  end

  def user_version
    @user_version ||= user_versions_presenter.user_version_for(version)&.to_i
  end

  def user_version_path
    item_public_version_path(item_id: druid, user_version_id: user_version)
  end

  def version_path
    item_version_path(item_id: druid, version_id: version)
  end

  def user_version_label
    "Public version #{user_version}"
  end

  def cocina_for_version?
    @cocina_for_version ||= versions_presenter.cocina?(version)
  end

  attr_reader :druid, :version, :milestones_presenter, :user_versions_presenter, :versions_presenter

  delegate :current_version, :version_view, to: :versions_presenter

  delegate :user_version_view, :head_user_version, to: :user_versions_presenter
end
