# frozen_string_literal: true

# Compiles the summary of all the workflows for an object for the show page
class WorkflowService
  Workflow = Struct.new(:name, :complete, :error_count, keyword_init: true) do
    def complete?
      complete
    end
  end

  # @return [Array<Workflow>] the summary of the workflows sorted by workflow name
  def self.workflows_for(druid:)
    all_workflows = workflow_client.workflow_routes.all_workflows pid: druid
    all_workflows.workflows.sort_by(&:workflow_name).map do |workflow|
      error_count = processes(workflow).select { |process| process.status == 'error' }.count
      Workflow.new(name: workflow.workflow_name, complete: workflow.complete?, error_count: error_count)
    end
  end

  # @return [Boolean] if the object has been submitted or not before
  def self.submitted?(druid:)
    return true if workflow_client.lifecycle(druid: druid, milestone_name: 'submitted')

    false
  end

  # @return [Boolean] if the object has been published or not before
  def self.published?(druid:)
    return true if workflow_client.lifecycle(druid: druid, milestone_name: 'published')

    false
  end

  # Get the workflow definition from the server so we know which processes should be present
  # TODO: This could be cached for better performance
  def self.definition_process_names(workflow_name)
    workflow_client.workflow_template(workflow_name).fetch('processes').map { |p| p['name'] }
  end
  private_class_method :definition_process_names

  # @return [Array] the list of processes for the given workflow
  def self.processes(workflow)
    definition_process_names(workflow.workflow_name).map do |process_name|
      workflow.process_for_recent_version(name: process_name)
    end
  end
  private_class_method :processes

  def self.workflow_client
    WorkflowClientFactory.build
  end
  private_class_method :workflow_client
end
