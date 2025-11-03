# frozen_string_literal: true

##
# Job to add a workflow to an object
class AddWorkflowJob < BulkActionJob
  def workflow_name
    params.fetch(:workflow)
  end

  class AddWorkflowJobItem < BulkActionJobItem
    delegate :workflow_name, to: :job

    def perform
      return unless check_update_ability?

      return failure!(message: "#{workflow_name} already exists") if workflow_active?

      open_new_version_if_needed!(description: "Started #{workflow_name}")

      Dor::Services::Client.object(druid).workflow(workflow_name).create(version: cocina_object.version)
      success!(message: "Started #{workflow_name}")
    end

    def workflow_active?
      WorkflowService.workflow_active?(druid: druid, wf_name: workflow_name, version: cocina_object.version)
    end
  end
end
