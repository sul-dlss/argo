# frozen_string_literal: true

##
# job to set tags on objects
class SetTagsJob < GenericJob
  queue_as :default

  DELIM = "\t"

  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      log_buffer.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.map { |druid_with_tag| druid_with_tag.split(DELIM) }.each do |pid|
        log_buffer.puts("#{Time.current} #{self.class}: Attempting to set tags for #{pid[0]} (bulk_action.id=#{bulk_action_id})")
        set_tags(pid[0], pid[1], log_buffer)
      end

      log_buffer.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def set_tags(current_druid, tags, log_buffer)
    Dor::Services::Client.object(current_druid).administrative_tags.create(tags: tags)

    log_buffer.puts("#{Time.current} #{self.class}: Successfully set tags for #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end
end
