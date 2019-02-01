# frozen_string_literal: true

# Displays a single step in a workflow for a single object/version
class WorkflowProcessPresenter
  ALLOWABLE_CHANGES = {
    'hold' => 'waiting',
    'waiting' => 'completed',
    'error' => 'waiting'
  }.freeze

  def initialize(view:, process_status:)
    @view = view
    @process_status = process_status
  end

  delegate :name, :status, :datetime, :attempts, :lifecycle, :note, to: :process_status

  def elapsed
    return unless process_status.elapsed

    format('%.3f', process_status.elapsed.to_f)
  end

  def reset_button
    return unless new_status

    # workflow update requires id, workflow, process, and status parameters
    form_tag item_workflow_path(pid, workflow_name) do
      hidden_field_tag('process', name) +
        hidden_field_tag('status', new_status) +
        button_tag('Set to ' + new_status, type: 'submit')
    end
  end

  private

  attr_reader :view, :process_status

  delegate :form_tag, :item_workflow_path, :hidden_field_tag, :button_tag, to: :view
  delegate :pid, :workflow_name, to: :process_status

  def new_status
    @new_status ||= ALLOWABLE_CHANGES[status]
  end
end
