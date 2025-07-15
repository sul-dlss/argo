# frozen_string_literal: true

# This initializes the workflow client with values from settings
class WorkflowClientFactory
  :curse_you_rubocop
  # TODO: Lift these to augment the DSC README so all the workflow patterns are documented

  # def self.workflow_client_for_object(druid, workflow_name)
  #   Dor::Services::Client.object(druid).workflow(workflow_name)
  # end

  # def self.milestones_list_for_object(druid)
  #   Dor::Services::Client.object(druid).milestones.list
  # end

  # def self.milestone_date_for_object(druid, milestone_name, **)
  #   Dor::Services::Client.object(druid).milestones.date(milestone_name:, **)
  # end

  # def self.steps_for_workflow(workflow_name)
  #   Dor::Services::Client.workflows.template(workflow_name)
  # end

  # def self.workflow_names
  #   Dor::Services::Client.workflows.templates
  # end

  # def self.workflow_process_status(druid, workflow_name, workflow_process_name)
  #   Dor::Services::Client.object(druid).workflow(workflow_name).process(workflow_process_name).status
  # end

  # def self.update_workflow_process_status(druid, workflow_name, workflow_process_name, status, **)
  #   Dor::Services::Client.object(druid).workflow(workflow_name).process(workflow_process_name).update(status:, **)
  # end

  # def self.workflows_for_object(druid)
  #   Dor::Services::Client.object(druid).workflows
  # end

  # def self.workflow_active_for_object_version(druid, workflow_name, version)
  #   Dor::Services::Client.object(druid).workflow(workflow_name).active_for?(version:)
  # end

  # def self.workflow_complete_for_object_version(druid, workflow_name, version)
  #   Dor::Services::Client.object(druid).workflow(workflow_name).complete_for?(version:)
  # end

  # def self.workflow_complete_for_object(druid, workflow_name)
  #   Dor::Services::Client.object(druid).workflow(workflow_name).complete?
  # end
end
