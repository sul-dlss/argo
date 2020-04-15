# frozen_string_literal: true

class WorkflowTableComponent < ApplicationComponent
  def initialize(name:, data:)
    @name = name
    @data = data
  end

  attr_reader :name, :data

  def workflow_name
    new_params = search_state.add_facet_params('wf_wps_ssim', name).merge(controller: 'catalog', action: 'index')
    link_to(name, new_params)
  end

  def workflow_process_names
    client = WorkflowClientFactory.build
    workflow_definition = client.workflow_template(name)
    workflow_definition['processes'].collect { |process| [process['name'], process['label']] }
  rescue Dor::WorkflowException
    Honeybadger.notify("no workflow template found for '#{name}'")
    []
  end
end
