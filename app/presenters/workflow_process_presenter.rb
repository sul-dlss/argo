# frozen_string_literal: true

# Displays a single step in a workflow for a single object/version
class WorkflowProcessPresenter
  # @param [Object] view the view context
  # @param [Dor::Workflow::Response::Process] process_status the model for the WorkflowProcess
  def initialize(view:, process_status:)
    @view = view
    @process_status = process_status
  end

  delegate :name, :status, :datetime, :attempts, :lifecycle, :note, :error_message, to: :process_status

  def elapsed
    return unless process_status.elapsed

    format('%.3f', process_status.elapsed.to_f)
  end

  def status_action
    case status
    when 'error'
      error_choices
    when 'waiting'
      completed_button('completed')
    end
  end

  private

  attr_reader :view, :process_status

  delegate :form_tag, :item_workflow_path, :hidden_field_tag, :button_tag, :content_tag, :options_for_select, :select_tag, to: :view
  delegate :pid, :repository, :workflow_name, to: :process_status

  CONFIRM_MESSAGE = 'You have selected to manually change the status. ' \
    'This could result in processing errors. Are you sure you want to proceed?'

  def error_choices
    # workflow update requires id, workflow, process, and status parameters
    form_tag item_workflow_path(pid, workflow_name), method: 'put' do
      hidden_field_tag('process', name) +
        hidden_field_tag('repo', repository) +
        content_tag(:div, class: 'input-group') do
          select_tag('status',
                     options_for_select([['Rerun', 'waiting'], ['Skip', 'skipped'], ['Complete', 'completed']]),
                     prompt: 'Select',
                     class: 'form-control') +
            content_tag(:span, class: 'input-group-btn') do
              button_tag('Save', type: 'submit',
                                 class: 'btn btn-default',
                                 data: { confirm: CONFIRM_MESSAGE })
            end
        end
    end
  end

  def completed_button(new_status)
    # workflow update requires id, workflow, process, and status parameters
    form_tag item_workflow_path(pid, workflow_name), method: 'put' do
      hidden_field_tag('process', name) +
        hidden_field_tag('repo', repository) +
        hidden_field_tag('status', new_status) +
        button_tag('Set to ' + new_status, type: 'submit', class: 'btn btn-default')
    end
  end
end
