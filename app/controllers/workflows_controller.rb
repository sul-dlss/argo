# frozen_string_literal: true

class WorkflowsController < ApplicationController
  ##
  # Renders a view with process-level state information for a given object's workflow.
  #
  # @option params [String] `:item_id` The druid for the object.
  # @option params [String] `:id` The workflow name. e.g., accessionWF.
  def show
    workflow = WorkflowClientFactory.build.workflow(pid: params[:item_id], workflow_name: params[:id])
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
    return redirect_to solr_document_path(cocina_object.externalIdentifier), flash: { error: "#{wf_name} already exists!" } if workflow_active?(wf_name, cocina_object.externalIdentifier, cocina_object.version)

    WorkflowClientFactory.build.create_workflow_by_name(cocina_object.externalIdentifier,
                                                        wf_name,
                                                        version: cocina_object.version)

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
    WorkflowClientFactory.build.workflow_status(druid: params[:item_id],
                                                workflow: params[:id],
                                                process: params[:process])
    # update the status for the step and redirect to the workflow view page
    WorkflowClientFactory.build.update_status(druid: params[:item_id],
                                              workflow: params[:id],
                                              process: params[:process],
                                              status: params[:status])
    msg = "Updated #{params[:process]} status to '#{params[:status]}' in #{params[:item_id]}"
    redirect_to solr_document_path(params[:item_id]), notice: msg
  end

  def history
    @history_xml = WorkflowClientFactory.build.workflow_routes.all_workflows(pid: params[:item_id]).xml

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  delegate :can_update_workflow?, to: :current_ability

  # Fetches the workflow from the workflow service and checks to see if it's active
  def workflow_active?(wf_name, druid, version)
    client = WorkflowClientFactory.build
    workflow = client.workflow(pid: druid, workflow_name: wf_name)
    workflow.active_for?(version:)
  end

  def build_show_presenter(workflow)
    return WorkflowXmlPresenter.new(xml: workflow.xml) if params[:raw]

    status = WorkflowStatus.new(workflow:,
                                workflow_steps: workflow_processes(params[:id]))
    WorkflowPresenter.new(view: view_context,
                          workflow_status: status,
                          cocina_object: Repository.find(params[:item_id]))
  end

  def workflow_processes(workflow_name)
    client = WorkflowClientFactory.build
    workflow_definition = client.workflow_template(workflow_name)
    workflow_definition['processes'].map { |process| process['name'] } # rubocop:disable Rails/Pluck
  end
end
