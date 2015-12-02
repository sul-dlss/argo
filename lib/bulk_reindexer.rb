module Argo
  ##
  # Handles Bulk reindexing jobs, by queueing up pids
  class BulkReindexer
    attr_reader :pid_lists

    ##
    # Creates an instance of Argo::BulkReindexer
    # @param [Array<Array<String>>] pid_lists [['druid:abc123']]
    def initialize(pid_lists)
      @pid_lists = pid_lists
    end

    ##
    # Batch up and enqueue IndexingJobs
    # @param [Array<String>] pid_list
    # @param [Integer] priority
    def queue_pid_reindexing_jobs(pid_list, priority = 1)
      pid_list.each_slice(Settings.BULK_REINDEXER.BATCH_SIZE) do |sublist|
        IndexingJob.delay(priority: priority).perform_later(sublist)
      end
    end

    ##
    # Prioritize and send pid_lists to be enqueued with a priority
    def queue_prioritized_pid_lists_for_reindexing
      pid_lists.each_with_index do |pid_list, priority|
        queue_pid_reindexing_jobs pid_list, priority
      end
    end

    ##
    # Create an instance of Argo::BulkReindexer with all pids, prioritize, and
    # enqueue all of the pids
    def self.reindex_all
      new(
        Argo::PidGatherer.new.pid_lists_for_full_reindex
      ).queue_prioritized_pid_lists_for_reindexing
    end
  end
end
