# frozen_string_literal: true

# Compiles the summary of all the workflows for an object for the show page
class WorkflowService
  # @return [Array<Dor::Services::Response::Workflow>] the summary of the workflows sorted by workflow name
  def self.workflows_for(druid:)
    Dor::Services::Client.object(druid).workflows.workflows.sort_by(&:workflow_name)
  end

  # @return [Boolean] if the object has been submitted or not before
  def self.submitted?(druid:)
    return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'submitted')

    false
  end

  # @return [Boolean] if the object has been published or not before
  def self.published?(druid:)
    return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'published')

    false
  end

  # @return [Boolean] if the object has been accessioned or not before
  def self.accessioned?(druid:)
    return true if Dor::Services::Client.object(druid).milestones.date(milestone_name: 'accessioned')

    false
  end

  # Fetches the workflow from the workflow service and checks to see if it's active
  # @return [Boolean] if the object has an active workflow
  def self.workflow_active?(druid:, version:, wf_name:)
    Dor::Services::Client.object(druid).workflow(wf_name).find.active_for?(version:)
  end
end
