# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  helper HierarchyHelper

  def solr_doc_params(id=nil)
    id ||= params[:id]
    {
      :q => %{PID:"#{id}"}
    }
  end

end 
