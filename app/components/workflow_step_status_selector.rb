# frozen_string_literal: true

# Draws a dropdown of choices for the status of a workflow step
class WorkflowStepStatusSelector < ApplicationComponent
  CONFIRM_MESSAGE = 'You have selected to manually change the status. ' \
                    'This could result in processing errors. Are you sure you want to proceed?'

  # @param [Dor::Services::Response::Process] process_status the model for the WorkflowProcess
  def initialize(process:)
    @process = process
  end

  delegate :workflow_name, :name, to: :process

  # This is the message displayed in a confirm dialog when you submit the form.
  def confirm
    CONFIRM_MESSAGE
  end

  def workflow_step_status_options
    options = [%w[Rerun waiting]]
    options.push(%w[Skip skipped], %w[Complete completed]) if allow_skip_or_complete?(name)
    options
  end

  private

  def druid
    process.pid
  end

  attr_reader :process
end
