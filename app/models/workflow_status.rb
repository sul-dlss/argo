# frozen_string_literal: true

# Represents the status of an item in the workflow
class WorkflowStatus
  # @param [Dor::Workflow::Response::Workflow] workflow the response from the workflow service for this object/workflow_name
  # @param [Array<String>] workflow_steps a list of steps in the workflow
  def initialize(workflow:, workflow_steps:)
    @workflow = workflow
    @workflow_steps = workflow_steps
  end

  delegate :empty?, :workflow_name, :pid, to: :workflow

  def process_statuses
    return [] if empty?

    workflow_steps.map do |process|
      workflow.process_for_recent_version(name: process)
    end
  end

  private

  attr_reader :workflow_steps, :workflow
end
