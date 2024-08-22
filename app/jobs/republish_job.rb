# frozen_string_literal: true

##
# job to republish objects
class RepublishJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count

      druids.each do |current_druid|
        log_buffer.puts("#{Time.current} #{self.class}: Attempting to republish #{current_druid} (bulk_action.id=#{bulk_action_id})")
        republish(current_druid, log_buffer)
      end
    end
  end

  private

  def republish(current_druid, log_buffer)
    if !publishable?(Repository.find(current_druid))
      log_buffer.puts("#{Time.current} #{self.class}: Did not republish #{current_druid} because only items and collections may be published (bulk_action.id=#{bulk_action.id})")
      bulk_action.increment(:druid_count_fail).save
    elsif WorkflowService.published?(druid: current_druid)
      Dor::Services::Client.object(current_druid).publish(lane_id: 'low')
      log_buffer.puts("#{Time.current} #{self.class}: Successfully published #{current_druid} (bulk_action.id=#{bulk_action.id})")
      bulk_action.increment(:druid_count_success).save
    else
      log_buffer.puts("#{Time.current} #{self.class}: Did not republish #{current_druid} because it is never been published (bulk_action.id=#{bulk_action.id})")
      bulk_action.increment(:druid_count_fail).save
    end
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end

  def publishable?(maybe_cocina_object)
    return false if maybe_cocina_object.admin_policy? ||
                    maybe_cocina_object.type == Cocina::Models::ObjectType.agreement

    true
  rescue StandardError
    false
  end
end
