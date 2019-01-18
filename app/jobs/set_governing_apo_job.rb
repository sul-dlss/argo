# frozen_string_literal: true

##
# job to move an object to a new governing APO
class SetGoverningApoJob < GenericJob
  queue_as :set_governing_apo

  attr_reader :new_apo_id, :groups

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Hash] :set_governing_apo
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    @new_apo_id = params[:set_governing_apo]['new_apo_id']
    @pids = params[:pids]
    @groups = params[:groups]

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting SetGoverningApoJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} SetGoverningApoJob: Starting update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_governing_apo_and_index_safely(current_druid, log)
        log.puts("#{Time.current} SetGoverningApoJob: Finished update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
      end

      Dor::SearchService.solr.commit
      log.puts("#{Time.current} Finished SetGoverningApoJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def set_governing_apo_and_index_safely(current_druid, log)
    current_obj = Dor.find(current_druid)

    check_can_set_governing_apo!(current_obj)

    open_new_version(current_obj, 'Set new governing APO') unless current_obj.allows_modification?

    current_obj.admin_policy_object = Dor.find(new_apo_id)
    current_obj.identityMetadata.adminPolicy = nil if current_obj.identityMetadata.adminPolicy # no longer supported, erase if present as a bit of remediation
    current_obj.save
    Dor::SearchService.solr.add current_obj.to_solr

    log.puts("#{Time.current} SetGoverningApoJob: Successfully updated #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue => e
    log.puts("#{Time.current} SetGoverningApoJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e} #{e.backtrace}")
    bulk_action.increment(:druid_count_fail).save
  end

  def check_can_set_governing_apo!(obj)
    raise "#{obj.pid} is not open for modification" unless obj.allows_modification?
    raise "user not authorized to move #{obj.pid} to #{new_apo_id}" unless ability.can?(:manage_governing_apo, obj, new_apo_id)
  end
end
