##
# Base IndexingJob class
class IndexingJob < ActiveJob::Base
  queue_as :indexing

  ##
  # Perform indexing job
  # @param [Array] pid_list
  # @param [Boolean] should_commit
  # @param [Boolean] should_profile
  def perform(pid_list, should_commit = false, should_profile = false)
    if should_profile
      Argo::Indexer.reindex_pid_list_with_profiling pid_list, should_commit
    else
      Argo::Indexer.reindex_pid_list pid_list, should_commit
    end
  end
end
