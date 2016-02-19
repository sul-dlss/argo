module Argo
  ##
  # Handles Bulk reindexing jobs, by queueing up batches of pids for
  # processing by delayed jobs workers.
  class BulkReindexer
    attr_reader :pid_lists

    ##
    # Creates an instance of Argo::BulkReindexer
    # @param [Array<Array<String>>] pid_lists [['druid:abc123']] A list of lists to be reindexed,
    #   in order of priority.  that is, pid_lists[0] is indexed first, pid_lists[1] second, etc).
    def initialize(pid_lists)
      @pid_lists = pid_lists
    end

    ##
    # Batch up and enqueue IndexingJobs.  pid_list is broken into batches of BATCH_SIZE, and
    #  an indexing job of the given priority is submitted for each batch.
    # @param [Array<String>] pid_list
    # @param [Integer] priority
    def queue_pid_reindexing_jobs(pid_list, priority = 1)
      pid_list.each_slice(Settings.BULK_REINDEXER.BATCH_SIZE) do |sublist|
        IndexingJob.delay(priority: priority).perform_later(sublist)
      end
    end

    ##
    # Enqueue each list from the overall list, specifying appropriate priority info.
    # Lower numbers indicate higher priority, and the lists should be processed in the
    # order in which each appears in the overall list, so just use the index of the sublist
    # from the overall list as the priority.
    def queue_prioritized_pid_lists_for_reindexing
      pid_lists.each_with_index do |pid_list, priority|
        queue_pid_reindexing_jobs pid_list, priority
      end
    end

    ##
    # Create an instance of Argo::BulkReindexer with all pids according to Fedora queries.
    # Prioritize the retrieved pids and enqueue indexing jobs.
    def self.reindex_all
      new(
        Argo::PidGatherer.new.pid_lists_for_full_reindex
      ).queue_prioritized_pid_lists_for_reindexing
    end
  end
end
