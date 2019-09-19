# frozen_string_literal: true

# Draws a reset button if the workflow step is errored or a complete button otherwise
class WorkflowUpdateButton < ApplicationComponent
  # @param [Dor::Workflow::Response::Process] process_status the model for the WorkflowProcess
  def initialize(process:)
    @process = process
  end

  delegate :pid, :workflow_name, :repository, :name, to: :process

  def label
    "Set to #{next_status}"
  end

  def next_status
    error_state? ? 'waiting' : 'completed'
  end

  def completed?
    process.status == 'completed'
  end

  private

  attr_reader :process

  delegate :status, to: :process

  def error_state?
    process.status == 'error'
  end
end
