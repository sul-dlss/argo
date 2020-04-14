# frozen_string_literal: true

class WorkflowTableProcessComponent < ApplicationComponent
  # TODO
  def initialize(workflow_table_process:, name:, data:)
    @process, @description = workflow_table_process
    @name = name
    @data = data
  end

  attr_reader :name, :data, :process, :description

  def workflow_process_name
    new_params = search_state.add_facet_params('wf_wps_ssim', [name, process].compact.join(':')).merge(controller: 'catalog', action: 'index')
    link_to(process, new_params)
  end

  def workflow_item_count(status)
    new_params = search_state.add_facet_params('wf_wps_ssim', [name, process, status].compact.join(':')).merge(controller: 'catalog', action: 'index')
    rotate_facet_params('wf_wps', 'wps', facet_order('wf_wps'), new_params)
    item_count = 0
    if data[process] && data[process][status] && item = data[process][status][:_] # rubocop:disable Lint/AssignmentInCondition
      item_count = item.hits
    end
    item_count = content_tag :span, item_count, class: 'zero' if item_count.zero?
    link_to(item_count, new_params)
  end

  def workflow_reset_link(status = 'error')
    return unless data[process] && data[process][status] && data[process][status][:_]

    new_params = search_state.add_facet_params(
      'wf_wps_ssim',
      [name, process, status].compact.join(':')
    )
                             .merge(
                               reset_workflow: name,
                               reset_step: process
                             )
    # rubocop:disable Rails/OutputSafety
    raw ' | ' + link_to('reset', report_reset_path(new_params), remote: true, method: :post)
    # rubocop:enable Rails/OutputSafety
  end
end
