# frozen_string_literal: true

module Argo
  class Indexer
    # Use the dor-indexing-app service to reindex a pid
    # @param [String] pid the druid
    # @raise [Exceptions::ReindexError] on failure
    def self.reindex_pid_remotely(pid)
      pid = "druid:#{pid}" unless pid =~ /^druid:/
      response = nil
      realtime = Benchmark.realtime do
        with_retries(max_tries: 3, rescue: [Errno::ECONNREFUSED]) do
          response = Faraday.post("#{Settings.dor_indexing_url}/reindex/#{pid}", '')
        end
      end
      raise "Unsuccessful: #{response.status}" unless response.success?

      Rails.logger.info "successfully updated index for #{pid} in #{format('%.3f', realtime)}s"
    rescue StandardError => e
      msg = "failed to reindex #{pid}: #{e}"
      Rails.logger.error msg
      raise Exceptions::ReindexError, msg
    end
  end
end
