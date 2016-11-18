require 'blacklight/catalog'

class ReportController < CatalogController

  include Blacklight::Catalog
  helper ArgoHelper
  copy_blacklight_config_from CatalogController

  def rsolr_request_error(exception)
    raise exception
  end

  def bulk
    (@response, @document_list) = search_results(params)
  end

  def data
    params[:sord] ||= 'asc'
    rows_per_page = params[:rows] ? params.delete(:rows).to_i : 10
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i, 1].max
    @report = Report.new(params, current_user: current_user)

    respond_to do |format|
      format.json do
        render :json => {
          :page    => params[:page].to_i,
          :records => @report.num_found,
          :total   => (@report.num_found / rows_per_page.to_f).ceil,
          :rows    => @report.report_data
        }
      end
      format.xml { render :xml => @report.report_data }
    end
  end

  def content_types
  end

  def pids
    respond_to do |format|
      format.json do
        render :json => {
          :druids => Report.new(params, current_user: current_user).pids(
            source_id: params[:source_id].present?,
            tags: params[:tags].present?
          )
        }
      end
    end
  end

  def download
    fields = params['fields'].present? ? params.delete('fields').split(/\s*,\s*/) : nil
    params[:per_page] = 10
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=report.csv'
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = Report.new(params, fields, current_user: current_user).to_csv
  end

  # an ajax call to reset workflow states for objects
  def reset
    head 501 unless request.xhr?

    fail ArgumentError, 'Missing reset_workflow' unless params[:reset_workflow].present?
    fail ArgumentError, 'Missing reset_step' unless params[:reset_step].present?

    @workflow = params[:reset_workflow]
    @step = params[:reset_step]
    @repo = repo_from_workflow(@workflow)
    @ids  = Report.new(params, current_user: current_user).pids
    @ids.each do |pid|
      Dor::Config.workflow.client.update_workflow_status(
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
    (@response, @document_list) = search_results(params)

    if request.xhr?
      render :partial => 'workflow_grid'
      return
    end

    respond_to do |format|
      format.html
    end
  end

  private

  ##
  # @return [String, nil]
  def repo_from_workflow(workflow)
    Dor::WorkflowObject.find_by_name(workflow).try(:definition).try(:repo)
  end
end
