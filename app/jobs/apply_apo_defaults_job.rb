# frozen_string_literal: true

##
# job to apply APO defaults to a set of items
class ApplyApoDefaultsJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count

      pids.each do |current_druid|
        apply_default(current_druid, log_buffer)
      end
    end
  end

  private

  def apply_default(current_druid, log_buffer)
    log_buffer.puts("#{Time.current} #{self.class}: Attempting to apply defaults to #{current_druid} (bulk_action.id=#{bulk_action.id})")
    cocina = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina)
      log_buffer.puts("#{Time.current} Not authorized for #{current_druid}")
      return
    end

    Dor::Services::Client.object(current_druid).apply_admin_policy_defaults

    log_buffer.puts("#{Time.current} #{self.class}: Successfully applied defaults to #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end
end
