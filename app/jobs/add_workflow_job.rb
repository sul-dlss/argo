# frozen_string_literal: true

##
# Job to add a workflow to and object
class AddWorkflowJob < GenericJob
  attr_reader :workflow_name

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [String] :workflow the name of the workflow to start
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @workflow_name = params.fetch(:workflow)
    with_bulk_action_log do |log|
      update_druid_count

      pids.each { |current_druid| start_workflow(current_druid, log) }
    end
  end

  private

  def start_workflow(current_druid, log)
    cocina_object = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina_object)
      bulk_action.increment(:druid_count_fail).save
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end

    # check the workflow is present and active (not archived)
    if workflow_active?(cocina_object.externalIdentifier, cocina_object.version)
      bulk_action.increment(:druid_count_fail).save
      log.puts("#{Time.current} #{workflow_name} already exists for #{current_druid}")
      return
    end

    client.create_workflow_by_name(cocina_object.externalIdentifier,
                                   workflow_name,
                                   version: cocina_object.version)
    log.puts("#{Time.current} started #{workflow_name} for #{current_druid}")

    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log.puts("#{Time.current} Workflow creation failed #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end

  # Fetches the workflow from the workflow service and checks to see if it's active
  def workflow_active?(druid, version)
    workflow = client.workflow(pid: druid, workflow_name: workflow_name)
    workflow.active_for?(version: version)
  end

  def client
    @client ||= WorkflowClientFactory.build
  end
end
