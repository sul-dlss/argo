# frozen_string_literal: true

class ReportController < CatalogController
  include Blacklight::Catalog
  helper ArgoHelper
  copy_blacklight_config_from CatalogController

  def rsolr_request_error(exception)
    raise exception
  end

  def bulk
    (@response, _deprecated_document_list) = search_service.search_results
  end

  def data
    params[:sord] ||= 'asc'
    rows_per_page = params[:rows] ? params.delete(:rows).to_i : 10
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i, 1].max
    @report = Report.new(params, current_user: current_user)

    respond_to do |format|
      format.json do
        render json: {
          page: params[:page].to_i,
          records: @report.num_found,
          total: (@report.num_found / rows_per_page.to_f).ceil,
          rows: @report.report_data
        }
      end
      format.xml { render xml: @report.report_data }
    end
  end

  def content_types; end

  def pids
    respond_to do |format|
      format.json do
        render json: {
          druids: Report.new(params, current_user: current_user).pids(
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
    params[:page] = 1
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=report.csv'
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = Report.new(params, fields, current_user: current_user).to_csv
  end

  # an ajax call to reset workflow states for objects
  def reset
    head :not_implemented unless request.xhr?

    params.require(%i[reset_workflow reset_step])

    @workflow = params[:reset_workflow]
    @step = params[:reset_step]
    @ids = Report.new(params, current_user: current_user).pids
    @ids.each do |pid|
      druid = "druid:#{pid}"
      cocina = Dor::Services::Client.object(druid).find
      next unless current_ability.can_update_workflow?('waiting', cocina)

      WorkflowClientFactory.build.update_status(
        druid: druid,
        workflow: @workflow,
        process: @step,
        status: 'waiting'
      )
    end
  end

  # This draws the full page that supports the workflow grid
  def workflow_grid
    (@response, _deprecated_document_list) = search_service.search_results
    return unless request.headers['X-Requester'] == 'frontend'

    # This is triggered by javascript that refreshes the data every 10s
    facet_id = 'wf_wps_ssim'
    facet = blacklight_config.facet_fields[facet_id]
    display_facet = @response.aggregations[facet.field]
    presenter = facet.presenter.new(facet, display_facet, self, search_state)
    @facet_tree = Blacklight::Hierarchy::FacetTree.build(
      prefix: 'wf_wps',
      facet_display: blacklight_config.facet_display,
      facet_field: presenter
    )[facet_id]

    render partial: 'workflow_grid'
  end
end
