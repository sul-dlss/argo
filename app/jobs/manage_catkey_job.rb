# frozen_string_literal: true

##
# Job to update/add catkey to objects
class ManageCatkeyJob < GenericJob
  attr_reader :catkeys

  ##
  # A job that allows a user to specify a list of pids and a list of catkeys to be associated with these pids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of
  # @option params [Hash] :manage_catkeys (required) list of catkeys to be associated 1:1 with pids in order
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @catkeys = params[:manage_catkeys]['catkeys'].split.map(&:strip)
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting ManageCatkeyJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each_with_index { |current_druid, i| update_catkey(current_druid, @catkeys[i], log) }
      log.puts("#{Time.current} Finished ManageCatkeyJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def update_catkey(current_druid, new_catkey, log)
    log.puts("#{Time.current} Beginning ManageCatkeyJob for #{current_druid}")
    cocina = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end
    log.puts("#{Time.current} Adding catkey of #{new_catkey}")
    begin
      object_client = Dor::Services::Client.object(current_druid)
      dro = object_client.find
      state_service = StateService.new(current_druid, version: dro.version)
      open_new_version(dro.externalIdentifier, dro.version, "Catkey updated to #{new_catkey}") unless state_service.allows_modification?

      CatkeyService.update(dro, object_client, new_catkey)
      bulk_action.increment(:druid_count_success).save
      log.puts("#{Time.current} Catkey added/updated/removed successfully")
    rescue StandardError => e
      log.puts("#{Time.current} Catkey failed #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
      nil
    end
  end
end
