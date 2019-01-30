# frozen_string_literal: true

# Shows a single step in a workflow for a single object/version
class WorkflowProcessPresenter
  ALLOWABLE_CHANGES = {
    'hold' => 'waiting',
    'waiting' => 'completed',
    'error' => 'waiting'
  }.freeze

  def initialize(view:, name:, pid:, workflow_name:, **attributes)
    @attributes = attributes
    @view = view
    @attributes[:name] = name
    @attributes[:pid] = pid
    @attributes[:workflow_name] = workflow_name
  end

  def name
    @attributes[:name]
  end

  def status
    @attributes[:status]
  end

  def datetime
    @attributes[:datetime]
  end

  def elapsed
    return unless @attributes[:elapsed]

    format('%.3f', @attributes[:elapsed].to_f)
  end

  def attempts
    @attributes[:attempts]
  end

  def lifecycle
    @attributes[:lifecycle]
  end

  def note
    @attributes[:note].presence
  end

  def reset_button
    # workflow update requires id, workflow, process, and status parameters
    form_tag item_workflow_path(pid, workflow_name) do
      hidden_field_tag('process', name) +
        hidden_field_tag('status', new_status) +
        button_tag('Set to ' + new_status, type: 'submit')
    end
  end

  private

  attr_reader :view

  delegate :form_tag, :item_workflow_path, :hidden_field_tag, :button_tag, to: :view

  def pid
    @attributes[:pid]
  end

  def workflow_name
    @attributes[:workflow_name]
  end

  def new_status
    @new_status ||= ALLOWABLE_CHANGES.fetch(status, '')
  end
end
