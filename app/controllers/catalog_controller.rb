# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  helper HierarchyHelper

  def default_html_head
    super
    stylesheet_links << 'hierarchy' << 'argonauta'
    javascript_includes << 'hierarchy' << 'application'
  end

  def solr_doc_params(id=nil)
    id ||= params[:id]
    {
      :q => %{PID:"#{id}"}
    }
  end

end 
