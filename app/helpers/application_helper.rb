# frozen_string_literal: true

module ApplicationHelper
  def application_name
    'Argo'
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

  def avalaible_ocr_languages
    ABBYY_LANGUAGES.map { |lang| [lang, lang.gsub(/[ ()]/, '')] }
  end
end
