##
# Base IndexingJob class
class IndexingJob < ActiveJob::Base
  queue_as :indexing

  ##
  # Perform indexing job
  # @param [Array] pid_list
  def perform(pid_list)
    if Settings.INDEXING_JOB.SHOULD_PROFILE
      Argo::Indexer.reindex_pid_list_with_profiling pid_list, Settings.INDEXING_JOB.SHOULD_COMMIT_BATCHES
    else
      Argo::Indexer.reindex_pid_list pid_list, Settings.INDEXING_JOB.SHOULD_COMMIT_BATCHES
    end
  end
end
