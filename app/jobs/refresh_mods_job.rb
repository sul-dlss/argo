# frozen_string_literal: true

##
# job to refresh the descriptive metadata from Symphony
class RefreshModsJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      log_buffer.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log_buffer.puts("#{Time.current} #{self.class}: Attempting #{current_druid} (bulk_action.id=#{bulk_action_id})")
        refresh_mods(current_druid, log_buffer)
      end

      log_buffer.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def refresh_mods(current_druid, log_buffer)
    object_client = Dor::Services::Client.object(current_druid)
    cocina_object = object_client.find

    return unless verify_access(cocina_object, log_buffer) && verify_catkey(cocina_object, log_buffer)

    object_client.refresh_descriptive_metadata_from_ils
    log_buffer.puts("#{Time.current} #{self.class}: Successfully updated metadata #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts "#{Time.current} #{self.class}: Unexpected error for #{current_druid}: (bulk_action.id=#{bulk_action.id}): #{e.message}"
    bulk_action.increment(:druid_count_fail).save
  end

  def verify_access(cocina_object, log_buffer)
    return true if ability.can?(:manage_item, cocina_object)

    log_buffer.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
    bulk_action.increment(:druid_count_fail).save
    false
  end

  def verify_catkey(cocina_object, log_buffer)
    catkey = cocina_object.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
    return true if catkey.present?

    log_buffer.puts("#{Time.current} #{self.class}: Did not update metadata for #{cocina_object.externalIdentifier} because it " \
                    "doesn't have a catkey (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_fail).save
    false
  end
end
