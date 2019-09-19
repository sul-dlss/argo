# frozen_string_literal: true

class WorkflowPresenter
  # @param [Object] view the rails view context
  # @param [WorkflowStatus] workflow_status
  def initialize(view:, workflow_status:)
    @view = view
    @workflow_status = workflow_status
  end

  delegate :pid, :workflow_name, to: :workflow_status

  # @return [Array] all the steps in the workflow definition
  def processes
    workflow_status.process_statuses
  end

  private

  attr_reader :workflow_status, :view
end
