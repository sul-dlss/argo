# frozen_string_literal: true

module Argo
  class Indexer
    # Use the dor-indexing-app service to reindex a pid
    # @param [String] pid the druid
    # @raise [Exceptions::ReindexError] on failure
    def self.reindex_pid_remotely(pid)
      pid = "druid:#{pid}" unless pid =~ /^druid:/
      realtime = Benchmark.realtime do
        with_retries(max_tries: 3, rescue: [RestClient::Exception, Errno::ECONNREFUSED]) do
          RestClient.post("#{Settings.DOR_INDEXING_URL}/reindex/#{pid}", '')
        end
      end
      Rails.logger.info "successfully updated index for #{pid} in #{format('%.3f', realtime)}s"
    rescue RestClient::Exception, Errno::ECONNREFUSED => e
      msg = "failed to reindex #{pid}: #{e}"
      Rails.logger.error msg
      raise Exceptions::ReindexError, msg
    rescue StandardError => e
      Rails.logger.error "failed to reindex #{pid}: #{e}"
      raise
    end
  end
end
