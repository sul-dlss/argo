# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ReportController < CatalogController

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  helper ArgoHelper
  copy_blacklight_config_from CatalogController
  
  def default_html_head
    super
    stylesheet_links << ['ui.jqgrid']
    javascript_includes << ['report']
  end
  
  def rsolr_request_error(exception)
    raise exception
  end
  def bulk
    (@response, @document_list) = get_search_results
  end
  def data
    #if (not params[:sidx]) or params[:sidx] == 'druid'
    #  params[:sidx] = 'id'
    #end
    if not params[:sord]
      params[:sord] = 'asc'
    end
    #params[:sort] = "#{params.delete(:sidx)} #{params.delete(:sord)}" if params[:sidx].present?
    rows_per_page = params[:rows] ? params.delete(:rows).to_i : 10
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i,1].max

    delete_or_assign_search_session_params
    @report = Report.new(params)
    
    respond_to do |format|
      format.json { 
        render :json => {
          :page => params[:page].to_i,
          :records => @report.num_found,
          :total => (@report.num_found / rows_per_page.to_f).ceil,
          :rows => @report.report_data
        }
      }
      format.xml  { render :xml  => @report.report_data }
    end
  end
  def content_types
    
  end

  def pids
    #params[:per_page]=100
    #params[:rows]=100
    fields=['druid']
    ids=Report.new(params,fields).pids params
    respond_to do |format|
      format.json { 
        render :json => {
          :druids => ids
        }
      }
    end
  end
  def download
    fields = params['fields'] ? params.delete('fields').split(/\s*,\s*/) : nil
    params[:per_page]=10
    self.response.headers["Content-Type"] = "application/octet-stream" 
    self.response.headers["Content-Disposition"] = "attachment; filename=report.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s
    self.response_body = Report.new(params,fields).csv2
  end

  # an ajax call to reset workflow states for objects
  def reset
    return unless request.xhr?
    @workflow=params[:reset_workflow]
    @step=params[:reset_step]
    @ids=Report.new(params,['druids']).pids params
    @ids.each { |pid| Dor::WorkflowService.update_workflow_status 'dor',"druid:#{pid}",@workflow, @step, "waiting" }
  end
    
  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results

    if request.xhr?
      render :partial => 'workflow_grid'
      return
    end 

    respond_to do |format|
      format.json
      format.html
    end
  end
end
