# frozen_string_literal: true

# Draws a reset button if the workflow step is errored
class WorkflowProcessRow < ApplicationComponent
  # @param [Dor::Workflow::Response::Process] process_status the model for the WorkflowProcess
  # @param [Integer] index the row index
  # @param [Dor::Item] item the repository object that the workflow is about
  def initialize(process:, index:, item:)
    @process = process
    @index = index
    @item = item
  end

  delegate :pid, :workflow_name, :repository, :name, :status, :datetime,
           :attempts, :lifecycle, :note, :error_message, to: :process

  def elapsed
    return unless process.elapsed

    format('%.3f', process.elapsed.to_f)
  end

  def error?
    status == 'error'
  end

  attr_reader :process, :index, :item
end
