# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ReportController < CatalogController

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
    # if !params[:sidx] || params[:sidx] == 'druid'
    #  params[:sidx] = 'id'
    # end
    params[:sord] ||= 'asc'
    # params[:sort] = "#{params.delete(:sidx)} #{params.delete(:sord)}" if params[:sidx].present?
    rows_per_page = params[:rows] ? params.delete(:rows).to_i : 10
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i, 1].max

    @report = Report.new(params)

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

  def content_types
  end

  def pids
    # params[:per_page]=100
    # params[:rows]=100
    ids = Report.new(params, ['druid']).pids params
    respond_to do |format|
      format.json do
        render :json => {
          :druids => ids
        }
      end
    end
  end

  def download
    fields = params['fields'] ? params.delete('fields').split(/\s*,\s*/) : nil
    params[:per_page] = 10
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=report.csv'
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = Report.new(params, fields).to_csv
  end

  # an ajax call to reset workflow states for objects
  def reset
    render nothing: true, status: 501 unless request.xhr?
    @workflow = params[:reset_workflow]
    @step = params[:reset_step]
    @ids  = pids_from_report(params)
    @repo = repo_from_workflow(params[:reset_workflow])
    @ids.each do |pid|
      Dor::WorkflowService.update_workflow_status(
        @repo,
        "druid:#{pid}",
        @workflow,
        @step,
        'waiting'
      )
    end
    ### XXX: Where's the authorization?
  end

  def workflow_grid
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

  private

  ##
  # @return [Array]
  def pids_from_report(params)
    Report.new(params, ['druids']).pids params
  end

  ##
  # @return [String, nil]
  def repo_from_workflow(workflow)
    Dor::WorkflowObject.find_by_name(workflow).try(:definition).try(:repo)
  end
end
