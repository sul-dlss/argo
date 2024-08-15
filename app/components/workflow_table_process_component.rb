# frozen_string_literal: true

class WorkflowTableProcessComponent < ApplicationComponent
  def initialize(workflow_table_process:, name:, data:)
    @process, @description = workflow_table_process
    @name = name
    @data = data
  end

  attr_reader :name, :data, :process, :description

  def workflow_process_name
    new_params = search_state.filter('wf_wps_ssim').add([name, process].compact.join(':')).params.merge(
      controller: 'catalog', action: 'index'
    )
    link_to(process, new_params)
  end

  def workflow_item_count(status)
    new_params = search_state.filter('wf_wps_ssim').add([name, process, status].compact.join(':')).params.merge(
      controller: 'catalog', action: 'index'
    )
    rotate_facet_params('wf_wps', 'wps', facet_order('wf_wps'), new_params)
    item_count = 0
    if data[process] && data[process][status] && (item = data[process][status][:_])
      item_count = item.hits
    end
    item_count = tag.span item_count, class: 'text-body-secondary' if item_count.zero?
    link_to(item_count, new_params)
  end

  def rotate_facet_params(prefix, from, to, p = params.dup)
    return p if from == to

    from_field = "#{prefix}_#{from}"
    to_field = "#{prefix}_#{to}"
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
    p[:f][from_field] = (p[:f][from_field] || []).dup
    p[:f][to_field] = (p[:f][to_field] || []).dup

    p[:f][from_field].reject! do |v|
      p[:f][to_field] << rotate_facet_value(v, from, to)
      true
    end

    p[:f].delete(from_field)
    p[:f][to_field].compact!
    p[:f].delete(to_field) if p[:f][to_field].empty?
    p
  end

  def rotate_facet_value(val, from, to)
    components = from.chars.zip(val.split(':')).to_h
    new_values = components.values_at(*to.chars)
    new_values.pop while new_values.last.nil?
    return nil if new_values.include?(nil)

    new_values.compact.join(':')
  end

  def facet_order(prefix)
    param_name = "#{prefix}_facet_order".to_sym # rubocop:disable Lint/SymbolConversion
    params[param_name] || blacklight_config.facet_display[:hierarchy][prefix].first
  end

  def workflow_reset_link(status = 'error')
    return unless data[process] && data[process][status] && data[process][status][:_]

    new_params = search_state.filter('wf_wps_ssim')
                             .add([name, process, status].compact.join(':'))
                             .params
                             .merge(
                               reset_workflow: name,
                               reset_step: process
                             )

    raw " | #{button_to('reset', report_reset_path(new_params), class: 'btn btn-link p-0 text-danger')}"
  end

  delegate :blacklight_config, to: :search_state
end
