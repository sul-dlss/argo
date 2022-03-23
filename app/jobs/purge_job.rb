# frozen_string_literal: true

##
# job to purge unpublished objects
class PurgeJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count

      druids.each do |current_druid|
        log_buffer.puts("#{Time.current} #{self.class}: Attempting to purge #{current_druid} (bulk_action.id=#{bulk_action_id})")
        purge(current_druid, log_buffer)
      end
    end
  end

  private

  def purge(current_druid, log_buffer)
    cocina = Dor::Services::Client.object(current_druid).find
    unless ability.can?(:manage_item, cocina)
      log.puts("#{Time.current} Not authorized to purge #{current_druid}")
      return
    end

    if WorkflowService.submitted?(druid: current_druid)
      log_buffer.puts("#{Time.current} #{self.class}: Cannot purge #{current_druid} because it has already been submitted (bulk_action.id=#{bulk_action.id})")

      bulk_action.increment(:druid_count_fail).save
      return
    end
    PurgeService.purge(druid: current_druid)

    log_buffer.puts("#{Time.current} #{self.class}: Successfully purged #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end

  def workflow_client
    WorkflowClientFactory.build
  end
end
