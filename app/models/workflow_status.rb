# frozen_string_literal: true

# Represents the status of an item in the workflow
class WorkflowStatus
  # @param [Dor::Workflow::Response::Workflow] workflow the response from the workflow service for this object/workflow_name
  # @param [Array<String>] workflow_steps a list of steps in the workflow
  def initialize(workflow:, workflow_steps:)
    @workflow = workflow
    @workflow_steps = workflow_steps
  end

  delegate :empty?, :workflow_name, to: :workflow

  def druid
    workflow.pid
  end

  def process_statuses
    return [] if empty?

    workflow_steps.map do |process|
      workflow.process_for_recent_version(name: process)
    end
  end

  # any workflow context that is set... context is returned with each process step, but is the same for all steps, so just return the first one
  def workflow_context
    process_statuses.filter_map(&:context).first
  end

  private

  attr_reader :workflow_steps, :workflow
end
