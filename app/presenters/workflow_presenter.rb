# frozen_string_literal: true

class WorkflowPresenter
  # @param [Object] view the rails view context
  # @param [WorkflowStatus] workflow_status
  def initialize(view:, workflow_status:)
    @view = view
    @workflow_status = workflow_status
  end

  delegate :pid, :workflow_name, to: :workflow_status

  # This iterates over all the steps in the workflow definition and creates a presenter
  # for each of the most recent version.
  # @return [Array<WorkflowProcessPresenter>]
  def processes
    workflow_status.process_statuses.map do |process|
      WorkflowProcessPresenter.new(view: view, process_status: process)
    end
  end

  private

  attr_reader :workflow_status, :view
end
