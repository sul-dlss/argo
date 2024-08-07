# frozen_string_literal: true

##
# job to reindex a DOR object to Solr using the dor_indexing_app endpoint
class RemoteIndexingJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count

      druids.each do |current_druid|
        log_buffer.puts("#{Time.current} RemoteIndexingJob: Attempting to index #{current_druid} (bulk_action.id=#{bulk_action_id})")
        reindex_druid_safely(current_druid, log_buffer)
      end
    end
  end

  private

  def reindex_druid_safely(current_druid, log_buffer)
    Dor::Services::Client.object(current_druid).reindex
    log_buffer.puts("#{Time.current} RemoteIndexingJob: Successfully reindexed #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts("#{Time.current} RemoteIndexingJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end
end
