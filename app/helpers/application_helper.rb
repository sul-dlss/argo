module ApplicationHelper
  include Rack::Webauth::Helpers

  def application_name
    'Argo'
  end

  def fedora_base
    URI.parse(Dor::Config.fedora.safeurl.sub(/\/*$/, '/'))
  end

  def inflect(str, num)
    '%d %s' % [num, (num == 1 ? str.singularize : str.pluralize)]
  end

  def robot_status_url
    Argo::Config.urls.robot_status
  end

  ##
  # Views used in report view toggle
  # @return [Array<ViewSwitcher>]
  def views_to_switch
    [
      ViewSwitcher.new(:catalog, :catalog_index_url),
      ViewSwitcher.new(:report, :report_url),
      ViewSwitcher.new(:discovery, :discovery_url),
      ViewSwitcher.new(:workflow_grid, :report_workflow_grid_url)
    ]
  end

  ##
  # @return [Boolean]
  def bulk_update_view?(params)
    params['controller'] == 'report' && params['action'] == 'bulk'
  end

  ##
  # @return [Boolean]
  def catalog_view?(params)
    params['controller'] == 'catalog'
  end

  ##
  # @return [Boolean]
  def report_view?(params)
    params['controller'] == 'report' && params['action'] == 'index'
  end

  ##
  # @return [Boolean]
  def discovery_view?(params)
    params['controller'] == 'discovery'
  end

  ##
  # @return [Boolean]
  def workflow_grid_view?(params)
    params['controller'] == 'report' && params['action'] == 'workflow_grid'
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
