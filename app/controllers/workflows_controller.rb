# frozen_string_literal: true

class WorkflowsController < ApplicationController
  ##
  # Renders a view with process-level state information for a given object's workflow.
  #
  # @option params [String] `:item_id` The druid for the object.
  # @option params [String] `:id` The workflow name. e.g., accessionWF.
  def show
    workflow = Dor::Services::Client.object(params[:item_id]).workflow(params[:id]).find
    respond_to do |format|
      format.html do
        @presenter = build_show_presenter(workflow)
        render 'show', layout: !request.xhr?
      end
      format.xml { render xml: }
    end
  end

  # Called from "Add Workflow" button. This is content for a modal invoked via XHR
  # so we don't want a layout.
  def new
    render 'new', layout: false
  end

  # add a workflow to an object if the workflow is not present in the active table
  def create
    cocina_object = Repository.find(params[:item_id])

    unless params[:wf]
      return respond_to do |format|
        format.html { render layout: !request.xhr? }
      end
    end
    wf_name = params[:wf]

    # check the workflow is present and active (not archived)
    return redirect_to solr_document_path(cocina_object.externalIdentifier), flash: { error: "#{wf_name} already exists!" } if WorkflowService.workflow_active?(druid: cocina_object.externalIdentifier, version: cocina_object.version, wf_name:)

    Dor::Services::Client.object(cocina_object.externalIdentifier).workflow(wf_name).create(version: cocina_object.version)

    # Force a Solr update before redirection.
    Dor::Services::Client.object(cocina_object.externalIdentifier).reindex

    msg = "Added #{wf_name}"
    redirect_to solr_document_path(cocina_object.externalIdentifier), notice: msg
  end

  ##
  # Updates the status of a specific workflow process step to a given status.
  #
  # @option params [String] `:item_id` The druid for the object.
  # @option params [String] `:id` The workflow name. e.g., accessionWF.
  # @option params [String] `:process` The workflow step. e.g., publish.
  # @option params [String] `:status` The status to which we want to reset the workflow.
  def update
    params.require %i[process status]
    cocina = Repository.find(params[:item_id])

    return render status: :forbidden, plain: 'Unauthorized' unless can_update_workflow?(params[:status], cocina)

    # this will raise an exception if the item doesn't have that workflow step
    raise 'undefined workflow step' if Dor::Services::Client.object(params[:item_id]).workflow(params[:id]).process(params[:process]).status.nil?

    # update the status for the step and redirect to the workflow view page
    Dor::Services::Client.object(params[:item_id]).workflow(params[:id]).process(params[:process]).update(status: params[:status])

    msg = "Updated #{params[:process]} status to '#{params[:status]}' in #{params[:item_id]}"
    redirect_to solr_document_path(params[:item_id]), notice: msg
  end

  def history
    @history_xml = Dor::Services::Client.object(params[:item_id]).workflows.xml.to_xml

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  delegate :can_update_workflow?, to: :current_ability

  def build_show_presenter(workflow)
    return WorkflowXmlPresenter.new(xml: workflow.xml) if params[:raw]

    status = WorkflowStatus.new(workflow:,
                                workflow_steps: workflow_processes(params[:id]))
    WorkflowPresenter.new(view: view_context,
                          workflow_name: params[:id],
                          workflow_status: status,
                          cocina_object: Repository.find(params[:item_id]))
  end

  def workflow_processes(workflow_name)
    Dor::Services::Client.workflows.template(workflow_name)['processes'].map { |process| process['name'] } # rubocop:disable Rails/Pluck
  end
end
