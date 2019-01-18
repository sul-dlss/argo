# frozen_string_literal: true

##
# job to reindex a DOR object to Solr using the dor_indexing_app endpoint
class RemoteIndexingJob < GenericJob
  queue_as :indexing_remote

  def perform(bulk_action_id, params)
    @pids = params[:pids]

    with_bulk_action_log do |log_buffer|
      log_buffer.puts("#{Time.current} Starting RemoteIndexingJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log_buffer.puts("#{Time.current} RemoteIndexingJob: Attempting to index #{current_druid} (bulk_action.id=#{bulk_action_id})")
        reindex_druid_safely(current_druid, log_buffer)
      end

      log_buffer.puts("#{Time.current} Finished RemoteIndexingJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def reindex_druid_safely(current_druid, log_buffer)
    Argo::Indexer.reindex_pid_remotely(current_druid)
    log_buffer.puts("#{Time.current} RemoteIndexingJob: Successfully reindexed #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue => e
    log_buffer.puts("#{Time.current} RemoteIndexingJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end
end
