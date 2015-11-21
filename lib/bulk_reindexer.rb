module Argo
  class BulkReindexer
    def self.queue_pid_reindexing_jobs(pid_list, should_commit = false, should_profile = false, priority = 1, batch_size = 10)
      pid_list.each_slice(batch_size) do |sublist|
        IndexingJob.delay(priority: priority).perform_later(sublist, should_commit, should_profile)
      end
    end

    def self.reindex_all(should_commit = true, should_profile = true)
      Argo::PidGatherer.new.pid_lists_for_full_reindex.each_with_index do |pid_list, priority|
        Argo::BulkReindexer.queue_pid_reindexing_jobs pid_list, should_commit, should_profile, priority
      end
    end
  end
end
