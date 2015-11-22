module Argo
  ##
  # Handles Bulk reindexing jobs, by queueing up pids
  class BulkReindexer
    attr_reader :should_commit, :should_profile, :pid_lists

    ##
    # Creates an instance of Argo::BulkReindexer
    # @param [Boolean] should_commit
    # @param [Boolean] should_profile
    # @param [Array<Array<String>>] pid_lists [['druid:abc123']]
    def initialize(should_commit, should_profile, pid_lists)
      @should_commit = should_commit
      @should_profile = should_profile
      @pid_lists = pid_lists
    end

    ##
    # Batch up and enqueue IndexingJobs
    # @param [Array<String>] pid_list
    # @param [Integer] priority
    # @param [Integer] batch_size
    def queue_pid_reindexing_jobs(pid_list, priority = 1, batch_size = 10)
      pid_list.each_slice(batch_size) do |sublist|
        IndexingJob.delay(priority: priority).perform_later(sublist, should_commit, should_profile)
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
    # @param [Boolean] should_commit
    # @param [Boolean] should_profile
    def self.reindex_all(should_commit = true, should_profile = true)
      new(
        should_commit,
        should_profile,
        Argo::PidGatherer.new.pid_lists_for_full_reindex
      ).queue_prioritized_pid_lists_for_reindexing
    end
  end
end
