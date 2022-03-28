# frozen_string_literal: true

##
# A background job to add a release tag and then start the release workflow
class ReleaseObjectJob < GenericJob
  attr_reader :manage_release

  ##
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [String] :to required release to target
  # @option params [String] :who required username of releaser
  # @option params [String] :what required type of release (self, collection)
  # @option params [String] :tag required (true, false)
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @manage_release = params
    with_bulk_action_log do |log|
      update_druid_count

      druids.each { |current_druid| release_object(current_druid, log) }
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
    object_client = Dor::Services::Client.object(cocina.externalIdentifier)
    object_client.update(params: model_with_new_release_tag(cocina))
    log.puts("#{Time.current} Release tag added successfully")
    true
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::Services::Client::Error => e
    log.puts("#{Time.current} Release tag failed POST #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
    false
  end

  # Return a copy of the existing cocina model with a new tag appended
  def model_with_new_release_tag(cocina)
    cocina.new(
      administrative: cocina.administrative.new(
        releaseTags: Array(cocina.administrative.releaseTags) + [new_tag]
      )
    )
  end

  def new_tag
    Cocina::Models::ReleaseTag.new(
      to: manage_release['to'],
      who: manage_release['who'],
      what: manage_release['what'],
      release: string_to_boolean(manage_release['tag']),
      date: DateTime.now.utc.iso8601
    )
  end

  def string_to_boolean(string)
    case string
    when 'true'
      true
    when 'false'
      false
    end
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
