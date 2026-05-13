# frozen_string_literal: true

class ReportController < CatalogController
  include Blacklight::Catalog
  include ActionController::Live

  helper ArgoHelper
  copy_blacklight_config_from CatalogController

  def rsolr_request_error(exception)
    raise exception
  end

  def data
    params[:per_page] = params[:per_page] ? params[:per_page].to_i : Report::ROWS_PER_PAGE
    # The client-side tooling will automagically increment this param as it
    # progressively loads report results via the server-side API
    # (ReportController & Report model).
    params[:page] ||= 1
    @report = Report.new(params, current_user:)

    respond_to do |format|
      format.json do
        # The returned JSON aligns the server-side impl with what the client-side wants.
        render json: {
          page: params[:page].to_i,
          last_page: (@report.num_found / params[:per_page].to_f).ceil,
          data: @report.report_data
        }
      end
      format.xml { render xml: @report.report_data }
    end
  end

  def download
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename="report.csv"'
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time

    Report.new(params, current_user:).stream_csv(stream: response.stream)
  end

  # reset workflow states for objects
  def reset
    params.require(%i[reset_workflow reset_step])

    workflow = params[:reset_workflow]
    step = params[:reset_step]
    ids = Report.new(params, current_user:).druids
    ids.each do |druid|
      druid = Druid.new(druid).with_namespace
      cocina = Repository.find(druid)

      next unless current_ability.can_update_workflow?('waiting', cocina)

      Dor::Services::Client.object(druid).workflow(workflow).process(step).update(status: 'waiting', current_status: 'error')
    rescue Dor::Services::Client::ConflictResponse => e
      # NOTE: this may be triggered if the step being set to waiting is no longer in error
      # which should not normally happen, because the list of druids fetched by `Report` should all be in error
      Honeybadger.notify(e, context: { druid: })
    end
    message = "#{ids.size} objects were reset back to waiting for #{workflow}:#{step}.  It may take a few seconds to update."
    redirect_back_or_to(report_workflow_grid_path, notice: message)
  end

  # This draws the full page that supports the workflow grid
  def workflow_grid
    (@response, _deprecated_document_list) = search_service.search_results
    return unless request.headers['X-Requester'] == 'frontend'

    # This is triggered by javascript that refreshes the data every 10s
    facet_id = SolrDocument::FIELD_WORKFLOW_WPS
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
