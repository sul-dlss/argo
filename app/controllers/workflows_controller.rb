# frozen_string_literal: true

class WorkflowsController < ApplicationController
  before_action :load_resource, except: [:history]

  ##
  # Renders a view with process-level state information for a given object's workflow.
  #
  # @option params [String] `:id` The druid for the object.
  # @option params [String] `:wf_name` The workflow name. e.g., accessionWF.
  # @option params [String] `:repo` The workflow's repository. e.g., dor.
  def show
    params.require(:repo)
    xml = Dor::Config.workflow.client.get_workflow_xml(params[:repo], params[:item_id], params[:wf_name])

    respond_to do |format|
      format.html do
        # rubocop:disable Rails/DynamicFindBy
        wf_def = Dor::WorkflowObject.find_by_name(params[:wf_name]).definition.processes
        # rubocop:enable Rails/DynamicFindBy
        @presenter = WorkflowPresenter.new(object: @object,
                                           workflow_name: params[:wf_name],
                                           xml: xml,
                                           workflow_steps: wf_def)
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
    [:process, :status].each { |p| params.require(p) }
    args = params.values_at(:item_id, :id, :process, :status)
    # rubocop:disable Rails/DynamicFindBy
    # the :repo parameter is optional, so fetch it based on the workflow name if blank
    params[:repo] ||= Dor::WorkflowObject.find_by_name(params[:id]).definition.repo
    # rubocop:enable Rails/DynamicFindBy

    # this will raise an exception if the item doesn't have that workflow step
    Dor::Config.workflow.client.get_workflow_status params[:repo], *args.take(3)
    # update the status for the step and redirect to the workflow view page
    Dor::Config.workflow.client.update_workflow_status params[:repo], *args
    respond_to do |format|
      if params[:bulk].present?
        render status: 200, plain: 'Updated!'
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
    wf = @object.workflows[wf_name]
    # check the workflow is present and active (not archived)
    if wf&.active?
      render status: 500, plain: "#{wf_name} already exists!"
      return
    end
    Dor::CreateWorkflowService.create_workflow(@object, name: wf_name)

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
    @history_xml = Dor::Config.workflow.client.get_workflow_xml 'dor', params[:item_id], nil

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def flush_index
    Dor::SearchService.solr.commit
  end

  def reindex(item)
    Dor::SearchService.solr.add item.to_solr
  end

  def load_resource
    @object = Dor.find params[:item_id]
  end
end
