# frozen_string_literal: true

##
# Job to add a workflow to and object
class AddWorkflowJob < GenericJob
  attr_reader :workflow_name

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [String] :workflow the name of the workflow to start
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @workflow_name = params.fetch(:workflow)
    with_items(params[:druids], name: 'Workflow creation') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      # check the workflow is present and active (not archived)
      next failure.call("#{workflow_name} already exists") if workflow_active?(cocina_object.externalIdentifier, cocina_object.version)

      client.create_workflow_by_name(cocina_object.externalIdentifier,
                                     workflow_name,
                                     version: cocina_object.version)
      success.call("started #{workflow_name}")
    end
  end

  private

  # Fetches the workflow from the workflow service and checks to see if it's active
  def workflow_active?(druid, version)
    workflow = client.workflow(pid: druid, workflow_name: workflow_name)
    workflow.active_for?(version: version)
  end

  def client
    @client ||= WorkflowClientFactory.build
  end
end
