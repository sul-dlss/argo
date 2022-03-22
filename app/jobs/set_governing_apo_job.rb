# frozen_string_literal: true

##
# job to move an object to a new governing APO
class SetGoverningApoJob < GenericJob
  attr_reader :new_apo_id

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Hash] :set_governing_apo
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @new_apo_id = params[:set_governing_apo]['new_apo_id']

    with_bulk_action_log do |log|
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} SetGoverningApoJob: Starting update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_governing_apo_and_index_safely(current_druid, log)
        log.puts("#{Time.current} SetGoverningApoJob: Finished update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
      end
    end
  end

  private

  def set_governing_apo_and_index_safely(current_druid, log)
    cocina_item = Dor::Services::Client.object(current_druid).find
    state_service = StateService.new(current_druid, version: cocina_item.version)
    raise "user not authorized to move #{current_druid} to #{new_apo_id}" unless ability.can?(:manage_governing_apo, cocina_item, new_apo_id)

    open_new_version(current_druid, cocina_item.version, 'Set new governing APO') unless state_service.allows_modification?

    change_set = ItemChangeSet.new(cocina_item)
    change_set.validate(admin_policy_id: new_apo_id)
    change_set.save

    log.puts("#{Time.current} SetGoverningApoJob: Successfully updated #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log.puts("#{Time.current} SetGoverningApoJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e} #{e.backtrace}")
    bulk_action.increment(:druid_count_fail).save
  end
end
