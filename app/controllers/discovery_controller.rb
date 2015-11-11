# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class DiscoveryController < CatalogController
  include BlacklightSolrExtensions
  include Blacklight::Catalog
  helper ArgoHelper
  copy_blacklight_config_from CatalogController

  def rsolr_request_error(exception)
    raise exception
  end

  def bulk
    (@response, @document_list) = get_search_results
  end

  def data
    params[:sord] ||= 'asc'
    rows_per_page = params[:rows] ? params.delete(:rows).to_i : 10
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i, 1].max

    @report = Discovery.new(params)

    respond_to do |format|
      format.json do
        render :json => {
          :page    => params[:page].to_i,
          :records => @report.num_found,
          :total   => (@report.num_found / rows_per_page.to_f).ceil,
          :rows    => @report.report_data
        }
      end
      format.xml  { render :xml  => @report.report_data }
    end
  end

  def download
    fields = params['fields'] ? params.delete('fields').split(/\s*,\s*/) : nil
    params[:per_page] = 10
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=report.csv'
    response.headers['Last-Modified'] = Time.now.ctime.to_s
    self.response_body = Discovery.new(params, fields).csv2
  end
end
