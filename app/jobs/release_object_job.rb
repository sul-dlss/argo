# frozen_string_literal: true

##
# Job to add release and then release a Dor Object
class ReleaseObjectJob < GenericJob
  queue_as :release_object

  attr_reader :manage_release, :pids, :groups
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
    @manage_release = params[:manage_release]
    @groups = params[:groups]
    @pids = params[:pids]
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting ReleaseObjectJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each { |current_druid| release_object(current_druid, log) }
      log.puts("#{Time.current} Finished ReleaseObjectJob for BulkAction #{bulk_action_id}")
    end
  end

  def can_manage?(pid)
    ability.can?(:manage_item, Dor.find(pid))
  end

  private

  def release_object(current_druid, log)
    log.puts("#{Time.current} Beginning ReleaseObjectJob for #{current_druid}")
    unless can_manage?(current_druid)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end
    log.puts("#{Time.current} Adding release tag for #{manage_release['to']}")
    begin
      Dor::Services::Client.object(current_druid).release_tags.create(
        to: manage_release['to'],
        who: manage_release['who'],
        what: manage_release['what'],
        release: string_to_boolean(manage_release['tag'])
      )
      log.puts("#{Time.current} Release tag added successfully")
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::Services::Client::Error => e
      log.puts("#{Time.current} Release tag failed POST #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
      return
    end
    log.puts("#{Time.current} Trying to start release workflow")
    begin
      Dor::Services::Client.object(current_druid).workflow.create(wf_name: 'releaseWF')
      log.puts("#{Time.current} Workflow creation successful")
      bulk_action.increment(:druid_count_success).save
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::Services::Client::Error => e
      log.puts("#{Time.current} Workflow creation failed POST #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
    end
  end

  def ability
    @ability ||= begin
      user = bulk_action.user
      # Since a user doesn't persist its groups, we need to pass the groups in here.
      user.set_groups_to_impersonate(groups)
      Ability.new(user)
    end
  end

  def string_to_boolean(string)
    case string
    when 'true'
      true
    when 'false'
      false
    end
  end

  def update_druid_count
    bulk_action.update(druid_count_total: pids.length)
    bulk_action.save
  end
end
