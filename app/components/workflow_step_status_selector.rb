# frozen_string_literal: true

# Draws a dropdown of choices for the status of a workflow step
class WorkflowStepStatusSelector < ApplicationComponent
  CONFIRM_MESSAGE = 'You have selected to manually change the status. ' \
    'This could result in processing errors. Are you sure you want to proceed?'

  # @param [Dor::Workflow::Response::Process] process_status the model for the WorkflowProcess
  def initialize(process:)
    @process = process
  end

  delegate :pid, :workflow_name, :repository, :name, to: :process

  # This is the message displayed in a confirm dialog when you submit the form.
  def confirm
    CONFIRM_MESSAGE
  end

  private

  attr_reader :process
end
