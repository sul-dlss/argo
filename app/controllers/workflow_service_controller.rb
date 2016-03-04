class WorkflowServiceController < ApplicationController
  ##
  # Is a document closeable?
  def closeable
    @status = workflow_status.can_close_version?
    render json: @status
  end

  ##
  # Is a document openable?
  def openable
    @status = workflow_status.can_open_version?
    render json: @status
  end

  ##
  # Has an object been published?
  def published
    @status = workflow_status.published?
    render json: @status
  end

  ##
  # Has an object been submitted?
  def submitted
    @status = workflow_status.submitted?
    render json: @status
  end

  ##
  # Has an object been accessioned?
  def accessioned
    @status = workflow_status.accessioned?
    render json: @status
  end

  private

  def workflow_status
    DorObjectWorkflowStatus.new(params[:pid])
  end
end
