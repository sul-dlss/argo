# frozen_string_literal: true

class WorkflowsController < ApplicationController
  before_action :load_resource, except: [:history]

  # Called from "Add Workflow" button. This is content for a modal invoked via XHR
  # so we don't want a layout.
  def new
    render 'new', layout: false
  end

  ##
  # Renders a view with process-level state information for a given object's workflow.
  #
  # @option params [String] `:item_id` The druid for the object.
  # @option params [String] `:id` The workflow name. e.g., accessionWF.
  # @option params [String] `:repo` The workflow's repository. e.g., dor.
  def show
    params.require(:repo)
    workflow = Dor::Config.workflow.client.workflow(repo: params[:repo], pid: params[:item_id], workflow_name: params[:id])
    respond_to do |format|
      format.html do
        @presenter = build_show_presenter(workflow)
        render 'show', layout: !request.xhr?
      end
      format.xml { render xml: xml }
    end
  end

  ##
  # Updates the status of a specific workflow process step to a given status.
  #
  # @option params [String] `:item_id` The druid for the object.
  # @option params [String] `:id` The workflow name. e.g., accessionWF.
  # @option params [String] `:process` The workflow step. e.g., publish.
  # @option params [String] `:status` The status to which we want to reset the workflow.
  # @option params [String] `:repo` The repo to which the workflow applies (optional).
  def update
    params.require [:process, :status, :repo]
    return render status: :forbidden, plain: 'Unauthorized' unless can_update_workflow?(params[:status], @object)

    # this will raise an exception if the item doesn't have that workflow step
    Dor::Config.workflow.client.workflow_status params[:repo], params[:item_id], params[:id], params[:process]
    # update the status for the step and redirect to the workflow view page
    Dor::Config.workflow.client.update_status(druid: params[:item_id],
                                              workflow: params[:id],
                                              process: params[:process],
                                              status: params[:status])
    respond_to do |format|
      if params[:bulk].present?
        render status: :ok, plain: 'Updated!'
      else
        msg = "Updated #{params[:process]} status to '#{params[:status]}' in #{params[:item_id]}"
        format.any { redirect_to solr_document_path(params[:item_id]), notice: msg }
      end
    end
  end

  # add a workflow to an object if the workflow is not present in the active table
  def create
    unless params[:wf]
      return respond_to do |format|
        format.html { render layout: !request.xhr? }
      end
    end
    wf_name = params[:wf]

    # check the workflow is present and active (not archived)
    if workflow_active?(wf_name)
      render status: :forbidden, plain: "#{wf_name} already exists!"
      return
    end

    Dor::Config.workflow.client.create_workflow_by_name(@object.pid, wf_name)

    # We need to sync up the workflows datastream with workflow service (using #find)
    # and then force a committed Solr update before redirection.
    reindex Dor.find(@object.pid)
    msg = "Added #{wf_name}"

    if params[:bulk]
      render plain: msg
    else
      redirect_to solr_document_path(@object.pid), notice: msg
    end
    flush_index
  end

  def history
    @history_xml = Dor::Config.workflow.client.all_workflows_xml params[:item_id]

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  delegate :can_update_workflow?, to: :current_ability

  # Fetches the workflow from the workflow service and checks to see if it's active
  def workflow_active?(wf_name)
    client = Dor::Config.workflow.client
    workflow = client.workflow(pid: @object.pid, workflow_name: wf_name)
    workflow.active_for?(version: @object.current_version)
  end

  def build_show_presenter(workflow)
    return WorkflowXmlPresenter.new(xml: workflow.xml) if params[:raw]

    status = WorkflowStatus.new(workflow: workflow,
                                workflow_steps: workflow_processes(params[:id]))
    WorkflowPresenter.new(view: view_context, workflow_status: status)
  end

  def workflow_processes(workflow_name)
    client = Dor::Config.workflow.client
    workflow_definition = client.workflow_template(workflow_name)
    workflow_definition['processes'].map { |process| process['name'] }
  end

  def flush_index
    ActiveFedora.solr.conn.commit
  end

  def reindex(item)
    ActiveFedora.solr.conn.add item.to_solr
  end

  def load_resource
    @object = Dor.find params[:item_id]
  end
end
