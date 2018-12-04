# frozen_string_literal: true

module Argo
  class Indexer < Dor::IndexingService
    # same as reindex_pid_list, but collect stats using argo's ruby-prof utility, and
    # output the results in the callgrind format.
    def self.reindex_pid_list_with_profiling(pid_list, should_commit = false)
      out_file_id = "reindex_pid_list_#{Time.now.iso8601}-#{Process.pid}"
      default_index_logger.info "#{out_file_id} traces bulk reindex for #{pid_list}"
      profiler = Argo::Profiler.new
      profiler.prof { Argo::Indexer.reindex_pid_list pid_list, should_commit }
      profiler.print_results_call_tree(out_file_id)
    end
  end
end
