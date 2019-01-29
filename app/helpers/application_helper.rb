# frozen_string_literal: true

module ApplicationHelper
  def application_name
    'Argo'
  end

  def fedora_base
    URI.parse(Dor::Config.fedora.safeurl.sub(/\/*$/, '/'))
  end

  def robot_status_url
    Settings.ROBOT_STATUS_URL
  end

  def location_to_send_search_form
    return report_path if report_view?
    return report_workflow_grid_path if workflow_grid_view?
    return search_profile_path if profile_view?

    search_catalog_path
  end

  ##
  # Views used in report view toggle
  # @return [Array<ViewSwitcher>]
  def views_to_switch
    [
      ViewSwitcher.new(:catalog, :search_catalog_url),
      ViewSwitcher.new(:report, :report_url),
      ViewSwitcher.new(:workflow_grid, :report_workflow_grid_url),
      ViewSwitcher.new(:profile, :search_profile_url)
    ]
  end

  ##
  # @return [Boolean]
  def bulk_update_view?
    current_page?(report_bulk_path)
  end

  ##
  # @return [Boolean]
  def catalog_view?
    current_page?(search_catalog_path)
  end

  ##
  # @return [Boolean]
  def report_view?
    current_page?(report_path)
  end

  ##
  # @return [Boolean]
  def workflow_grid_view?
    current_page?(report_workflow_grid_path)
  end

  ##
  # @return [Boolean]
  def profile_view?
    current_page?(search_profile_path)
  end

  ##
  # Add a pids_only=true parameter to create a "search of pids" to an existing
  # Blacklight::Search
  # @param [Blacklight::Search, nil]
  # @return [Hash]
  def search_of_pids(search)
    return '' unless search.present?

    search.query_params.merge('pids_only' => true)
  end
end
