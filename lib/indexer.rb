# frozen_string_literal: true

module Argo
  class Indexer
    # Use the dor-indexing-app service to reindex a druid
    # @param [String] druid the druid
    # @raise [Exceptions::ReindexError] on failure
    def self.reindex_druid_remotely(druid)
      druid = "druid:#{druid}" unless druid.start_with?('druid:')
      response = nil
      realtime = Benchmark.realtime do
        with_retries(max_tries: 3, rescue: [Errno::ECONNREFUSED]) do
          response = Faraday.post("#{Settings.dor_indexing_url}/reindex/#{druid}", '')
        end
      end
      raise "Unsuccessful: #{response.status}" unless response.success?

      Rails.logger.info "successfully updated index for #{druid} in #{format('%.3f', realtime)}s"
    rescue StandardError => e
      msg = "failed to reindex #{druid}: #{e}"
      Rails.logger.error msg
      raise Exceptions::ReindexError, msg
    end
  end
end
