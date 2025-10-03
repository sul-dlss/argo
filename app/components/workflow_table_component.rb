# frozen_string_literal: true

class WorkflowTableComponent < ApplicationComponent
  def initialize(name:, data:)
    @name = name
    @data = data
  end

  attr_reader :name, :data

  def workflow_name
    new_params = search_state.filter(SolrDocument::FIELD_WORKFLOW_WPS).add(name).params.merge(controller: 'catalog', action: 'index')
    link_to(name, new_params)
  end

  def workflow_process_names
    Dor::Services::Client.workflows
                         .template(name)['processes']
                         .map { |process| [process['name'], process['label']] }
  rescue Dor::Services::Client::NotFoundResponse
    Honeybadger.notify("no workflow template found for '#{name}'")
    []
  end
end
