# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  helper HierarchyHelper

  def default_html_head
    super
    stylesheet_links << 'ui-override'
  end

  def footer
    "\n<!-- #{@response['responseHeader']['params'].collect { |k,v| Array(v).collect { |a| "#{k}=#{a}" } }.flatten.join('&')} -->\n"
  end
end 
