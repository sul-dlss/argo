# frozen_string_literal: true

##
# Job to add release and then release a Dor Object
class ReleaseObjectJob < GenericJob
  attr_reader :manage_release

  ##
  # This is a shameless green approach to a job that calls release from dor
  # services app and then kicks off release WF.
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Hash] :manage_release required Hash of release options
  # @option manage_release [String] :to required release to target
  # @option manage_release [String] :who required username of releaser
  # @option manage_release [String] :what required type of release (self, collection)
  # @option manage_release [String] :tag required (true, false)
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @manage_release = params[:manage_release]
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting ReleaseObjectJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each { |current_druid| release_object(current_druid, log) }
      log.puts("#{Time.current} Finished ReleaseObjectJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def release_object(current_druid, log)
    log.puts("#{Time.current} Beginning ReleaseObjectJob for #{current_druid}")

    unless WorkflowService.published?(druid: current_druid)
      log.puts("#{Time.current} Object has never been published and cannot be released for #{current_druid}")
      return
    end

    cocina = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end

    log.puts("#{Time.current} Adding release tag for #{manage_release['to']}")

    create_release_tag(bulk_action, cocina, log) &&
      start_release_workflow(bulk_action, cocina, log)
  end

  def create_release_tag(bulk_action, cocina, log)
    Dor::Services::Client.object(cocina.externalIdentifier).release_tags.create(
      to: manage_release['to'],
      who: manage_release['who'],
      what: manage_release['what'],
      release: string_to_boolean(manage_release['tag'])
    )
    log.puts("#{Time.current} Release tag added successfully")
    true
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::Services::Client::Error => e
    log.puts("#{Time.current} Release tag failed POST #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
    false
  end

  def start_release_workflow(bulk_action, cocina, log)
    log.puts("#{Time.current} Trying to start release workflow")

    WorkflowClientFactory.build.create_workflow_by_name(cocina.externalIdentifier, 'releaseWF', version: cocina.version)
    log.puts("#{Time.current} Workflow creation successful")
    bulk_action.increment(:druid_count_success).save
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::WorkflowException => e
    log.puts("#{Time.current} Workflow creation failed POST #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end
end
