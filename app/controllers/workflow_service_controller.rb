class WorkflowServiceController < ApplicationController
  before_action :set_workflow_status

  ##
  # Is a document closeable?
  def closeable
    render json: @workflow_status.can_close_version?
  end

  ##
  # Is a document openable?
  def openable
    render json: @workflow_status.can_open_version?
  end

  ##
  # Has an object been published?
  def published
    render json: @workflow_status.published?
  end

  ##
  # Has an object been submitted?
  def submitted
    render json: @workflow_status.submitted?
  end

  ##
  # Has an object been accessioned?
  def accessioned
    render json: @workflow_status.accessioned?
  end

  private

  def set_workflow_status
    @workflow_status = DorObjectWorkflowStatus.new(params[:pid])
  end
end
