# frozen_string_literal: true

##
# Job to update/add catkey to objects
class ManageCatkeyJob < GenericJob
  queue_as :manage_catkey

  attr_reader :pids, :catkeys, :groups
  ##
  # A job that allows a user to specify a list of pids and a list of catkeys to be associated with these pids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Array] :catkeys required list of catkeys to be associated 1:1 with pids in order
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    @catkeys = params[:catkeys]
    @groups = params[:groups]
    @pids = params[:pids]
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting ManageCatkeyJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each_with_index { |current_druid, i| update_catkey(current_druid, catkeys[i], log) }
      log.puts("#{Time.current} Finished ManageCatkeyJob for BulkAction #{bulk_action_id}")
    end
  end

  def can_manage?(pid)
    ability.can?(:manage_item, Dor.find(pid))
  end

  private

  def update_catkey(current_druid, new_catkey, log)
    log.puts("#{Time.current} Beginning ManageCatkeyJob for #{current_druid}")
    unless can_manage?(current_druid)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end
    log.puts("#{Time.current} Adding catkey of #{new_catkey}")
    begin
      log.puts("#{Time.current} Catkey added successfully")
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Dor::Services::Client::Error => e
      log.puts("#{Time.current} Catkey failed POST #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
      return
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

  def update_druid_count
    bulk_action.update(druid_count_total: pids.length)
    bulk_action.save
  end
end
