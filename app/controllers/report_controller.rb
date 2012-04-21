# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ReportController < CatalogController

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  helper ArgoHelper
  helper HierarchyHelper
#  copy_blacklight_config_from CatalogController
  
  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    if request.xhr?
      render :partial => 'workflow_grid'
    else
      render
    end
  end
  
end
